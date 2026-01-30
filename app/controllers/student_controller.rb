# app/controllers/student_controller.rb
require_relative '../core/observer'
require_relative '../views/dialogs/student_dialog'

class StudentController
  include Observer
  
  def initialize(model)
    @model = model
  end
  
  # Обработка событий от View
  def on_observable_event(event_type, data = nil, observable = nil)
    case event_type
    when :sort_column
      sort_by_column(data)
    when :page_changed
      change_page(data)
    end
  end
  
  # Команды от пользователя
  def add_student
    show_student_dialog(nil) do |student_data|
      if student_data
        create_student(student_data)
        true
      else
        false
      end
    end
  end
  
  def edit_student(student)
    return unless student
    
    show_student_dialog(student) do |student_data|
      if student_data
        update_student(student, student_data)
        true
      else
        false
      end
    end
  end
  
  def delete_students(student_ids)
    return if student_ids.empty?
    
    message = "Вы уверены, что хотите удалить #{student_ids.size} студента(ов)?"
    if confirm_dialog("Подтверждение удаления", message)
      student_ids.each { |id| @model.delete_student_by_id(id) }
    end
  end
  
  def apply_filters(filters)
    @model.update_filters(filters)
  end
  
  def reset_filters
    @model.update_filters({})
  end
  
  # ФИКС: Правильная логика переключения направления сортировки
  def sort_by_column(column_index)
    if @model.sort_column == column_index
      # Тот же столбец - меняем направление
      new_direction = @model.sort_direction == :asc ? :desc : :asc
    else
      # Новый столбец - сортируем по возрастанию
      new_direction = :asc
    end
    
    @model.update_sort(column_index, new_direction)
  end
  
  def change_page(page)
    @model.update_page(page)
  end
  
  def refresh_table
    @model.reload_filtered_data
  end
  
  private
  
  def show_student_dialog(student = nil, &on_save)
    if defined?(StudentDialog)
      title = student ? "Редактирование студента" : "Добавление студента"
      dialog = StudentDialog.new(nil, student, title)
      
      if dialog.execute != 0
        student_data = dialog.result
        on_save.call(student_data) if block_given?
      end
    else
      # Если диалога нет, создаем простой
      create_simple_dialog(student, &on_save)
    end
  end
  
  def create_simple_dialog(student = nil, &on_save)
    require 'fox16'
    include Fox
    
    dialog = FXDialogBox.new(nil, student ? "Редактирование студента" : "Добавление студента")
    
    result = FXMessageBox.question(dialog, MBOX_YES_NO, "Тест", 
              student ? "Редактировать студента?" : "Добавить тестового студента?")
    
    if result == MBOX_CLICKED_YES
      on_save.call({
        first_name: "Тест",
        last_name: "Студент",
        patronymic: "Тестович",
        git: "https://github.com/test",
        email: "test@example.com",
        phone: "+79161234567",
        telegram: "@testuser"
      }) if block_given?
    end
    
    dialog.execute
  end
  
  def create_student(student_data)
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
  end
  
  def update_student(old_student, student_data)
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
    
    @model.replace_student_by_id(old_student.id, updated_student)
  end
  
  def confirm_dialog(title, message)
    require 'fox16'
    include Fox
    
    FXMessageBox.question(nil, MBOX_YES_NO, title, message) == MBOX_CLICKED_YES
  end
end