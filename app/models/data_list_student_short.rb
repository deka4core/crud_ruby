require_relative 'data_list'
require_relative 'student_short'

class DataListStudentShort < DataList
 
  private
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