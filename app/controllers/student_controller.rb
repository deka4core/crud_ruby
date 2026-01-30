# app/controllers/student_controller.rb

require_relative '../views/dialogs/student_dialog'

class StudentController
  attr_reader :view, :model, :current_filters, :current_sort, :current_page
  
  def initialize(view, model)
    @view = view
    @model = model
    @selected_rows = []
    @current_filters = nil
    @current_sort = { column: 1, direction: :asc }
    @current_page = 1
    @items_per_page = 20
    @current_data = model.all_students
    sort_current_data
  end
  
  def on_selection_changed(selected_rows)
    @selected_rows = selected_rows
    update_buttons_state
  end
  
  def on_student_double_click(row)
    student_id = get_student_id_at_row(row)
    return unless student_id
    
    student = find_student_in_current_data(student_id)
    return unless student
    
    edit_student_dialog(student)
  end
  
  def on_page_changed(page)
    @current_page = page
    update_table_display
  end
  
  def sort_by_column(column_index)
    if @current_sort[:column] == column_index
      @current_sort[:direction] = (@current_sort[:direction] == :asc) ? :desc : :asc
    else
      @current_sort = { column: column_index, direction: :asc }
    end
    
    sort_current_data
    @current_page = 1
    update_table_display
  end
  
  def add_student
    show_student_dialog(nil) do |student_data|
      if student_data
        create_and_save_student(student_data)
        true
      else
        false
      end
    end
  end
  
  def edit_student
    return if @selected_rows.empty?
    
    student_id = get_student_id_at_row(@selected_rows.first)
    return unless student_id
    
    student = find_student_in_current_data(student_id)
    return unless student
    
    edit_student_dialog(student)
  end
  
  def delete_students
    return if @selected_rows.empty?
    
    ids = @selected_rows.map { |row| get_student_id_at_row(row) }
    
    message = "Вы уверены, что хотите удалить #{ids.size} студента(ов)?"
    if confirm_dialog("Подтверждение удаления", message)
      deleted_count = 0
      
      ids.each do |id|
        student = @model.get_student_by_id(id)
        next unless student
        
        if @model.delete_student_by_id(id)
          deleted_count += 1
        end
      end
      
      if deleted_count > 0
        @model.save_data
        apply_filters
        info_dialog("Удаление", "Удалено #{deleted_count} из #{ids.size} студентов")
      end
    end
  end
  
  def apply_filters
    filters = @view.filter_panel.get_filters if @view.respond_to?(:filter_panel) && @view.filter_panel
    
    @current_filters = filters
    reload_filtered_data
    @current_page = 1
    update_table_display
  end
    
  def reset_filters
    if @view.respond_to?(:filter_panel) && @view.filter_panel
      @view.filter_panel.reset
    end
    apply_filters
  end
  
  def refresh_table
    apply_filters
  end
  
  private
  
  def reload_filtered_data
    all_students = @model.all_students
    filtered_students = filter_students(all_students, @current_filters)
    @current_data = filtered_students
    sort_current_data
  end
  
  def filter_students(students, filters)
    return students unless filters
    
    students.select do |student|
      fio_match = true
      if filters[:fio] && !filters[:fio].empty?
        full_name = student.last_name_initials.downcase
        search_term = filters[:fio].downcase
        fio_match = full_name.include?(search_term)
      end
      
      git_match = field_filter(student, :git, filters[:git])
      email_match = field_filter(student, :email, filters[:email])
      phone_match = field_filter(student, :phone, filters[:phone])
      telegram_match = field_filter(student, :telegram, filters[:telegram])
      
      fio_match && git_match && email_match && phone_match && telegram_match
    end
  end
  
  def field_filter(student, field_name, filter)
    return true unless filter
    
    field_value = get_field_value(student, field_name)
    has_field = !field_value.nil? && !field_value.empty?
    
    case filter[:state]
    when "yes"
      if filter[:value] && !filter[:value].empty?
        has_field && field_value.downcase.include?(filter[:value].downcase)
      else
        has_field
      end
    when "no"
      !has_field
    when "any"
      true
    else
      true
    end
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
    
  def sort_current_data
    return if @current_data.empty?
    
    @current_data.sort_by!(&sort_proc)
    
    if @current_sort[:direction] == :desc
      @current_data.reverse!
    end
  end
  
  def sort_proc
    column = @current_sort[:column]
    
    case column
    when 0
      ->(s) { s.id }
    when 1
      ->(s) { s.last_name_initials.downcase }
    when 2
      ->(s) { [s.has_git? ? 0 : 1, s.git.to_s.downcase] }
    when 3
      ->(s) { [s.has_contact? ? 0 : 1, s.contact.to_s.downcase] }
    else
      ->(s) { s.id }
    end
  end
  
  def get_current_page_data
    start_index = (@current_page - 1) * @items_per_page
    end_index = start_index + @items_per_page - 1
    
    return [] if @current_data.empty? || start_index >= @current_data.size
    
    actual_end = [end_index, @current_data.size - 1].min
    @current_data[start_index..actual_end] || []
  end
  
  def show_student_dialog(student = nil, &on_save)
    require_relative '../views/dialogs/student_dialog'
    
    title = student ? "Редактирование студента" : "Добавление студента"
    dialog = StudentDialog.new(@view, student, title)
    
    if dialog.execute != 0
      student_data = dialog.result
      on_save.call(student_data) if block_given?
    end
  end
  
  def edit_student_dialog(student)
    show_student_dialog(student) do |student_data|
      if student_data
        update_and_save_student(student, student_data)
        true
      else
        false
      end
    end
  end
  
  def create_and_save_student(student_data)
    require_relative '../models/student'
    
    new_student = Student.new(
      first_name: student_data[:first_name],
      last_name: student_data[:last_name],
      patronymic: student_data[:patronymic],
      git: student_data[:git],
      email: student_data[:email],
      phone: student_data[:phone],
      telegram: student_data[:telegram]
    )
    
    @model.add_student(new_student)
    @model.save_data
    apply_filters
    info_dialog("Успех", "Студент добавлен успешно!")
  end
  
  def update_and_save_student(old_student, student_data)
    require_relative '../models/student'
    
    updated_student = Student.new(
      first_name: student_data[:first_name],
      last_name: student_data[:last_name],
      patronymic: student_data[:patronymic],
      git: student_data[:git],
      email: student_data[:email],
      phone: student_data[:phone],
      telegram: student_data[:telegram]
    )
    
    if @model.replace_student_by_id(old_student.id, updated_student)
      @model.save_data
      apply_filters
      info_dialog("Успех", "Студент обновлен успешно!")
    else
      error_dialog("Ошибка", "Не удалось обновить студента")
    end
  end
  
  def get_student_id_at_row(row)
    return unless @view.table && @view.table.respond_to?(:getItemText)
    @view.table.getItemText(row, 0).to_i
  end
  
  def find_student_in_current_data(student_id)
    @current_data.find { |s| s.id == student_id }
  end
  
  def update_buttons_state
    return unless @view.respond_to?(:update_buttons_state)
    @view.update_buttons_state(@selected_rows.size)
  end
  
  def update_table_display
    return unless @view.respond_to?(:display_data)
    
    page_data = get_current_page_data
    
    require_relative '../models/student_short'
    student_shorts = page_data.map { |s| StudentShort.from_student(s) }
    
    require_relative '../models/data_list_student_short'
    data_list = DataListStudentShort.new(student_shorts)
    
    @view.display_data(data_list, @current_data.size, @current_page)
  end
  
  def confirm_dialog(title, message)
    FXMessageBox.question(@view, MBOX_YES_NO, title, message) == MBOX_CLICKED_YES
  end
  
  def info_dialog(title, message)
    FXMessageBox.information(@view, MBOX_OK, title, message)
  end
  
  def error_dialog(title, message)
    FXMessageBox.error(@view, MBOX_OK, title, message)
  end
end