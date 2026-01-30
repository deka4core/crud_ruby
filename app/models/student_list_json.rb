# app/models/student_list_json.rb
require 'json'
require_relative 'student'
require_relative 'student_short'
require_relative '../core/observable'
require_relative 'student_filter'

class StudentsListJSON
  include Observable
  
  attr_reader :current_page, :items_per_page, :total_pages, :filtered_students, :students,
              :filters, :sort_column, :sort_direction
  
  def initialize(file_path = nil)
    @students = []
    @file_path = file_path
    
    # Пагинация
    @current_page = 1
    @items_per_page = 10
    @total_pages = 1
    
    # Фильтры и сортировка
    @filters = {}
    @sort_column = 1 # По ФИО по умолчанию
    @sort_direction = :asc
    @filter = StudentFilter.new if defined?(StudentFilter)
    @filtered_students = []
    
    load_data if file_path && File.exist?(file_path)
    reload_filtered_data
  end

  def load_data
    puts "Загрузка данных из #{@file_path}..."
    
    begin
      if File.exist?(@file_path)
        json_data = File.read(@file_path)
        data = JSON.parse(json_data, symbolize_names: true)
        
        puts "Прочитано записей из JSON: #{data.size}"
        
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
        
        puts "Успешно создано студентов: #{@students.size}"
      else
        puts "Файл не существует: #{@file_path}"
      end
    rescue => e
      puts "Ошибка загрузки данных: #{e.message}"
      puts e.backtrace
    end
  end

  def get_k_n_student_short_list(k, n)
    puts "Запрос страницы #{k}, элементов: #{n}"
    
    reload_filtered_data
    
    start_index = (k - 1) * n
    end_index = start_index + n - 1
    
    puts "Индекс начала: #{start_index}, конец: #{end_index}"
    puts "Всего отфильтрованных: #{@filtered_students.size}"
    
    page_students = @filtered_students[start_index...end_index] || []
    
    puts "Студентов на странице: #{page_students.size}"
    
    # Конвертируем в StudentShort
    result = page_students.map do |student|
      StudentShort.from_student(student)
    end
    
    puts "Создано StudentShort: #{result.size}"
    result
  end
  
  def get_filtered_count
    @filtered_students.size
  end
  
  def next_page
    puts "Следующая страница. Текущая: #{@current_page}, всего: #{@total_pages}"
    
    if @current_page < @total_pages
      @current_page += 1
      notify_observers(:page_changed, @current_page)
      true
    else
      false
    end
  end
  
  def prev_page
    puts "Предыдущая страница. Текущая: #{@current_page}"
    
    if @current_page > 1
      @current_page -= 1
      notify_observers(:page_changed, @current_page)
      true
    else
      false
    end
  end
  
  def set_page(page_num)
    puts "Установка страницы: #{page_num}"
    
    if page_num >= 1 && page_num <= @total_pages
      @current_page = page_num
      notify_observers(:page_changed, @current_page)
      true
    else
      false
    end
  end
  
  def reload_filtered_data
    # Применяем фильтры
    @filtered_students = if defined?(StudentFilter) && @filter
      @filter.apply_filters(@students, @filters)
    else
      @students.dup
    end
    
    # Сортируем
    sort_filtered_data
    
    # Рассчитываем пагинацию
    @total_pages = [1, (@filtered_students.size.to_f / @items_per_page).ceil].max
    
    # Корректируем текущую страницу
    if @current_page > @total_pages
      @current_page = @total_pages
    end
  end

  def add_student(student_data)
  puts "Добавление нового студента..."
  
  new_id = @students.empty? ? 1 : @students.map(&:id).max + 1
  
  student = Student.new(
    id: new_id,
    first_name: student_data[:first_name],
    last_name: student_data[:last_name],
    patronymic: student_data[:patronymic],
    git: student_data[:git],
    phone: student_data[:phone],
    telegram: student_data[:telegram],
    email: student_data[:email]
  )
  
  @students << student
  save_data
  reload_filtered_data
  notify_observers(:student_added, student)
  
  puts "Студент добавлен с ID: #{new_id}"
  student
end

def delete_student_by_id(id)
  puts "Удаление студента с ID: #{id}"
  
  student = get_student_by_id(id)
  return false unless student
  
  @students.reject! { |s| s.id == id }
  save_data
  reload_filtered_data
  notify_observers(:student_deleted, id)
  
  puts "Студент удален"
  true
end

def update_student(id, student_data)
  puts "Обновление студента с ID: #{id}"
  
  index = @students.find_index { |s| s.id == id }
  return false unless index
  
  updated_student = Student.new(
    id: id,
    first_name: student_data[:first_name],
    last_name: student_data[:last_name],
    patronymic: student_data[:patronymic],
    git: student_data[:git],
    phone: student_data[:phone],
    telegram: student_data[:telegram],
    email: student_data[:email]
  )
  
  @students[index] = updated_student
  save_data
  reload_filtered_data
  notify_observers(:student_updated, updated_student)
  
  puts "Студент обновлен"
  true
end

def save_data
  return unless @file_path
  
  puts "Сохранение данных..."
  
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
  puts "Данные сохранены в #{@file_path}"
end
  
  def get_student_by_id(id)
    @students.find { |student| student.id == id }
  end
  
  def replace_student_by_id(id, new_student)
    puts "Обновление студента с ID: #{id}"
    
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
    
    reload_filtered_data
    notify_observers(:student_updated)
    puts "Студент с ID #{id} обновлен"
    true
  end
  
  def get_all_students
    @students.dup
  end

  def update_filters(new_filters)
    @filters = new_filters
    @current_page = 1
    reload_filtered_data
    notify_observers(:filters_updated)  # Добавьте эту строку!
  end

  def update_sort(column_index, direction = :asc)
    @sort_column = column_index
    @sort_direction = direction
    
    sort_filtered_data
    notify_observers(:sort_updated)
  end

  private

  def sort_filtered_data
    return if @filtered_students.empty?
    
    case @sort_column
    when 0 # ID
      @filtered_students.sort_by!(&:id)
    when 1 # ФИО
      @filtered_students.sort_by! { |s| s.last_name_initials.to_s.downcase }
    when 2 # Git
      @filtered_students.sort_by! do |s| 
        git = s.git.to_s
        [git.empty? ? 1 : 0, git.downcase]
      end
    when 3 # Контакт
      @filtered_students.sort_by! do |s| 
        contact = s.contact.to_s
        [contact.empty? ? 1 : 0, contact.downcase]
      end
    end
    
    @filtered_students.reverse! if @sort_direction == :desc
  end
end