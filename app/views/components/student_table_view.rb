# app/views/components/student_table.rb
require 'fox16'
include Fox

class StudentTable < FXTable
  attr_reader :selected_ids
  
  def initialize(parent)
    super(parent, nil, 0, 
          TABLE_READONLY | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_COL_SIZABLE,
          :padding => 2)
    
    @selected_ids = []
    setup_table
  end
  
  def update_table(students)
    clearItems if numRows > 0
    
    if students && !students.empty?
      setTableSize(students.size, 4)
      
      students.each_with_index do |student, row|
        student_short = StudentShort.from_student(student)
        
        setItemText(row, 0, student.id.to_s)
        setItemText(row, 1, student_short.last_name_initials || "")
        setItemText(row, 2, student_short.git || "")
        setItemText(row, 3, student_short.contact || "")
      end
    else
      setTableSize(0, 4)
    end
    
    adjust_column_widths
    killSelection
    @selected_ids.clear
  end
  
  private
  
  def setup_table
    setTableSize(0, 4)
    setColumnText(0, "ID")
    setColumnText(1, "Фамилия И.О.")
    setColumnText(2, "Git")
    setColumnText(3, "Контакт")
    
    setColumnWidth(0, 60)
    setColumnWidth(1, 250)
    setColumnWidth(2, 200)
    setColumnWidth(3, 250)
    setRowHeaderWidth(40)
  end
  
  def adjust_column_widths
    (0...numColumns).each do |col|
      max_width = getColumnText(col).length * 10
      
      (0...numRows).each do |row|
        text = getItemText(row, col)
        max_width = [max_width, text.length * 8].max
      end
      
      setColumnWidth(col, [max_width + 10, 400].min)
    end
  end
end