# app/controllers/student_controller.rb
require_relative '../views/dialogs/student_dialog'

class StudentController
  def initialize(view, model)
    @view = view
    @model = model
    
    # Связываем View с Model
    @view.set_model(@model) if @view.respond_to?(:set_model)
    @view.set_controller(self) if @view.respond_to?(:set_controller)
  end
  
  def add_student
    # Найти родительское окно для диалога
    parent_window = find_parent_window(@view)
    
    dialog = StudentDialog.new(parent_window, "Добавление студента")
    result = dialog.execute
    
    if result && dialog.student_data
      begin
        @model.add_student(dialog.student_data)
        show_info("Студент успешно добавлен")
      rescue => e
        show_error("Ошибка при добавлении студента: #{e.message}")
      end
    end
  end
  
  def edit_student(student_id)
    # Найти студента
    student = @model.get_student_by_id(student_id)
    return unless student
    
    # Найти родительское окно
    parent_window = find_parent_window(@view)
    
    dialog = StudentDialog.new(parent_window, "Редактирование студента", student)
    result = dialog.execute
    
    if result && dialog.student_data
      begin
        @model.update_student(student_id, dialog.student_data)
        show_info("Данные студента обновлены")
      rescue => e
        show_error("Ошибка при обновлении: #{e.message}")
      end
    end
  end
  
  def delete_students(student_ids)
    return if student_ids.empty?
    
    # Подтверждение удаления
    message = if student_ids.size == 1
                "Вы уверены, что хотите удалить выбранного студента?"
              else
                "Вы уверены, что хотите удалить #{student_ids.size} студентов?"
              end
    
    if confirm_dialog(message)
      student_ids.each do |id|
        @model.delete_student_by_id(id)
      end
      
      show_info("Удалено: #{student_ids.size} студентов")
    end
  end
  
  def refresh_data
    @model.reload_filtered_data
    @view.update_view if @view.respond_to?(:update_view)
  end

  def sort_by_column(column_index)
    # Проверяем, что сортировка разрешена только для ID и ФИО
    if column_index == 0 || column_index == 1
      @model.update_sort(column_index) if @model.respond_to?(:update_sort)
    end
  end
  
  private
  
  def find_parent_window(widget)
    window = widget
    while window && !window.is_a?(FXMainWindow) && window.respond_to?(:parent)
      window = window.parent
    end
    window
  end
  
  def show_info(message)
    FXMessageBox.information(@view.app, MBOX_OK, "Информация", message)
  end
  
  def show_error(message)
    FXMessageBox.error(@view.app, MBOX_OK, "Ошибка", message)
  end
  
  def confirm_dialog(message)
    result = FXMessageBox.question(@view.app, MBOX_YES_NO, "Подтверждение", message)
    result == MBOX_CLICKED_YES
  end
end