require_relative 'data_list'
require_relative '../core/observable'

class DataListStudentShort < DataList
  include Observable
  
  attr_accessor :page_offset
  
  def initialize(data = [])
    super(data)
    @page_offset = 0
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
  
  def notify
    notify_observers(:table_params, {
      column_names: column_names,
      whole_entities_count: @data.size
    })
    
    # Передаем правильное смещение
    notify_observers(:table_data, {
      data_table: get_data(@page_offset)
    })
  end
  
  def update_data(new_data)
    @data = new_data.dup
    clear_selected
    
    notify
  end
  
  def data=(new_data)
    update_data(new_data)
  end
end