# app/models/data_list_student_short.rb
require_relative 'data_list'

class DataListStudentShort < DataList
  
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
end