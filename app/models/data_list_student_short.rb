# app/models/data_list_student_short.rb
require_relative 'data_list'
require_relative '../core/observable'

class DataListStudentShort < DataList
  include Observable
  
  def initialize(data = [])
    super(data)
    puts "DataListStudentShort создан, ID: #{object_id}, данных: #{data.size}"
  end
  
  def column_names
    ["Фамилия И.О.", "Git", "Контакт"]
  end
  
  def row_values(student_short)
    [
      student_short.last_name_initials || "",
      student_short.git || "",
      student_short.contact || ""
    ]
  end
  
  # Метод notify из ТЗ (Задание 1, пункт 3)
  def notify
    puts "DataListStudentShort.notify вызван (ID: #{object_id})"
    puts "Наблюдателей: #{observers.size}"
    
    # Уведомляем всех наблюдателей
    notify_observers(:table_params, {
      column_names: column_names,
      whole_entities_count: @data.size
    })
    
    notify_observers(:table_data, {
      data_table: get_data
    })
  end
  
  # Обновление данных без создания нового объекта (Задание 1, пункт 7)
  def update_data(new_data)
    puts "DataListStudentShort.update_data: обновление объекта #{object_id}"
    puts "Старых данных: #{@data.size}, новых: #{new_data.size}"
    
    @data = new_data.dup
    clear_selected
    
    # Уведомляем наблюдателей об изменении
    notify
  end
  
  # Для обратной совместимости
  def data=(new_data)
    update_data(new_data)
  end
end