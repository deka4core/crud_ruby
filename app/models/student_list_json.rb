# app/models/student_list_json.rb
require 'json'
require_relative 'student'
require_relative 'student_short'
require_relative 'data_list_student_short'
require_relative '../core/observable'

class StudentsListJSON
  include Observable
  
  attr_reader :file_path, :filters, :sort_column, :sort_direction, 
              :current_page, :items_per_page, :filtered_students
  
  def initialize(file_path = nil)
    @students = []
    @file_path = file_path
    
    # Состояние приложения
    @filters = {}
    @sort_column = 1
    @sort_direction = :asc
    @current_page = 1
    @items_per_page = 20
    @filtered_students = []
    
    load_data if file_path && File.exist?(file_path)
    
    # При загрузке сразу фильтруем и сортируем
    reload_filtered_data
  end

  def load_data
    return unless File.exist?(@file_path)
    
    json_data = File.read(@file_path)
    data = JSON.parse(json_data, symbolize_names: true)
    
    @students = data.map do |student_data|
      Student.new(
        id: student_data[:id],
        first_name: student_data[:first_name],
        last_name: student_data[:last_name],
        patronymic: student_data[:patronymic],
        git: student_data[:git],
        phone: student_data[:phone],
        telegram: student_data[:telegram],
        email: student_data[:email]
      )
    end
    
    reload_filtered_data
    notify_observers(:data_loaded)
  end

  def save_data
    return unless @file_path
    
    students_data = @students.map do |student|
      {
        id: student.id,
        first_name: student.first_name,
        last_name: student.last_name,
        patronymic: student.patronymic,
        git: student.git,
        phone: student.instance_variable_get(:@phone),
        telegram: student.instance_variable_get(:@telegram),
        email: student.instance_variable_get(:@email)
      }
    end
    
    File.write(@file_path, JSON.pretty_generate(students_data))
    notify_observers(:data_saved)
  end

  # Методы управления данными
  def get_student_by_id(id)
    @students.find { |student| student.id == id }
  end

  def add_student(student)
    new_id = @students.empty? ? 1 : @students.map(&:id).max + 1
    
    student_with_id = Student.new(
      first_name: student.first_name,
      last_name: student.last_name,
      patronymic: student.patronymic,
      id: new_id,
      git: student.git,
      phone: student.instance_variable_get(:@phone),
      telegram: student.instance_variable_get(:@telegram),
      email: student.instance_variable_get(:@email)
    )
    
    @students << student_with_id
    save_data
    reload_filtered_data
    notify_observers(:student_added, student_with_id)
    student_with_id
  end

  def replace_student_by_id(id, new_student)
    index = @students.find_index { |student| student.id == id }
    return false unless index
    
    @students[index] = Student.new(
      first_name: new_student.first_name,
      last_name: new_student.last_name,
      patronymic: new_student.patronymic,
      id: id,
      git: new_student.git,
      phone: new_student.instance_variable_get(:@phone),
      telegram: new_student.instance_variable_get(:@telegram),
      email: new_student.instance_variable_get(:@email)
    )
    
    save_data
    reload_filtered_data
    notify_observers(:student_updated, @students[index])
    true
  end

  def delete_student_by_id(id)
    student = get_student_by_id(id)
    initial_size = @students.size
    @students.reject! { |student| student.id == id }
    
    if initial_size != @students.size
      save_data
      reload_filtered_data
      notify_observers(:student_deleted, id)
      true
    else
      false
    end
  end

  def get_student_short_count
    @students.size
  end

  def all_students
    @students.dup
  end

  # Методы управления состоянием
  def update_filters(new_filters)
    @filters = new_filters || {}
    @current_page = 1
    reload_filtered_data
    notify_observers(:filters_updated, @filters)
  end

  # ФИКС: update_sort теперь принимает только явное направление
  def update_sort(column, direction)
    @sort_column = column
    @sort_direction = direction
    @current_page = 1
    sort_filtered_data
    notify_observers(:sort_updated, { column: column, direction: direction })
  end

  def update_page(page)
    @current_page = page
    notify_observers(:page_updated, page)
  end

  def reload_filtered_data
    @filtered_students = apply_filters(@students)
    sort_filtered_data
    notify_observers(:state_changed)
  end

  def apply_filters(students)
    return students unless @filters && !@filters.empty?
    
    students.select do |student|
      matches_all_filters?(student)
    end
  end

  def matches_all_filters?(student)
    # Проверка ФИО
    if @filters[:fio] && !@filters[:fio].empty?
      full_name = student.last_name_initials.downcase
      search_term = @filters[:fio].downcase
      return false unless full_name.include?(search_term)
    end
    
    # Проверка полей
    [:git, :email, :phone, :telegram].each do |field|
      filter = @filters[field]
      next unless filter
      
      field_value = get_field_value(student, field)
      has_field = !field_value.nil? && !field_value.empty?
      
      case filter[:state]
      when "yes"
        if filter[:value] && !filter[:value].empty?
          return false unless has_field && field_value.downcase.include?(filter[:value].downcase)
        else
          return false unless has_field
        end
      when "no"
        return false if has_field
      when "any"
        # Любое значение подходит
      else
        return false
      end
    end
    
    true
  end

  def get_field_value(student, field_name)
    case field_name
    when :git
      student.git
    when :email
      if student.respond_to?(:email)
        student.email
      elsif student.instance_variable_defined?(:@email)
        student.instance_variable_get(:@email)
      end
    when :phone
      if student.respond_to?(:phone)
        student.phone
      elsif student.instance_variable_defined?(:@phone)
        student.instance_variable_get(:@phone)
      end
    when :telegram
      if student.respond_to?(:telegram)
        student.telegram
      elsif student.instance_variable_defined?(:@telegram)
        student.instance_variable_get(:@telegram)
      end
    end
  end

  def sort_filtered_data
    return if @filtered_students.empty?
    
    # Сортируем
    @filtered_students.sort_by!(&sort_proc)
    
    # Если desc - разворачиваем
    if @sort_direction == :desc
      @filtered_students.reverse!
    end
  end

  def sort_proc
    column = @sort_column
    
    case column
    when 0  # ID
      ->(s) { s.id.to_i }
    when 1  # ФИО
      ->(s) { s.last_name_initials.to_s.downcase }
    when 2  # Git
      ->(s) { 
        git = s.git.to_s
        [git.empty? ? 1 : 0, git.downcase]
      }
    when 3  # Контакт
      ->(s) { 
        contact = s.contact.to_s
        [contact.empty? ? 1 : 0, contact.downcase]
      }
    else
      ->(s) { s.id.to_i }
    end
  end

  # Методы для получения данных для отображения
  def get_current_page_data
    start_index = (@current_page - 1) * @items_per_page
    end_index = start_index + @items_per_page - 1
    
    return [] if @filtered_students.empty? || start_index >= @filtered_students.size
    
    actual_end = [end_index, @filtered_students.size - 1].min
    @filtered_students[start_index..actual_end] || []
  end

  def get_student_short_list_for_page
    page_data = get_current_page_data
    page_data.map { |student| StudentShort.from_student(student) }
  end

  def get_data_list_for_page
    student_shorts = get_student_short_list_for_page
    DataListStudentShort.new(student_shorts)
  end

  def total_pages
    [1, (@filtered_students.size.to_f / @items_per_page).ceil].max
  end

  def total_filtered_students
    @filtered_students.size
  end
end