# app/views/components/student_table.rb
require 'fox16'
include Fox
require_relative '../../core/observable'

class StudentTable < FXTable
  include Observable
  
  attr_accessor :controller
  
  def initialize(parent, controller = nil)
    super(parent, 
          nil, 0, 
          TABLE_READONLY | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_COL_SIZABLE,
          :padding => 2)
    
    @controller = controller
    
    setup_table
    setup_event_handlers
  end
  
  def update_table(data_list)
    return unless data_list
    
    data_table = data_list.get_data
    
    clearItems if numRows > 0
    
    setTableSize(data_table.rows_count, data_table.columns_count)
    
    column_names = data_list.get_names  
    column_names.each_with_index do |name, col|
      setColumnText(col, name)
    end
    
    (0...data_table.rows_count).each do |row|
      (0...data_table.columns_count).each do |col|
        value = data_table.get_element(row, col)
        setItemText(row, col, value.to_s)
      end
    end
    
    adjust_column_widths
    killSelection
    update
    recalc
  end
  
  def selected_rows
    selected = []
    (0...numRows).each do |row|
      selected << row if rowSelected?(row)
    end
    selected
  end
  
  def selected_student_ids
    selected_rows.map { |row| getItemText(row, 0).to_i }
  end
  
  private
  
  def setup_table
    setTableSize(0, 4)
    
    setColumnText(0, "№")
    setColumnText(1, "Фамилия И.О.")
    setColumnText(2, "Git")
    setColumnText(3, "Контакт")
    
    # Верхние заголовки - сортировка
    @columnHeader = self.columnHeader
    @columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
      notify_observers(:sort_column, index)
    end
    
    # ЛЕВЫЕ заголовки - выделение и редактирование
    @rowHeader = self.rowHeader
    
    # Клик по левому заголовку строки
    @rowHeader.connect(SEL_COMMAND) do |sender, sel, index|
      killSelection
      selectRow(index, true)
      notify_observers(:selection_changed, selected_rows)
    end
    
    # ДВОЙНОЙ клик по левому заголовку
    @rowHeader.connect(SEL_DOUBLECLICKED) do |sender, sel, ptr|
      selected = selected_rows
      notify_observers(:student_double_clicked, selected.first) unless selected.empty?
    end
    
    setColumnWidth(0, 50)
    setColumnWidth(1, 250)
    setColumnWidth(2, 200)
    setColumnWidth(3, 250)
    
    begin
      setBackColor(FXRGB(255, 255, 255))
      setTextColor(FXRGB(0, 0, 0))
      setSelBackColor(FXRGB(200, 220, 240))
      setSelTextColor(FXRGB(0, 0, 0))
    rescue => e
    end
    
    setRowHeaderWidth(40)
  end
  
  def setup_event_handlers
    # Обработчик для обычных кликов по ЯЧЕЙКАМ таблицы
    connect(SEL_CHANGED) do |sender, sel, ptr|
      notify_observers(:selection_changed, selected_rows)
    end
  end
    
  def adjust_column_widths
    (0...numColumns).each do |col|
      header_text = @columnHeader.getItemText(col)
      max_width = header_text.length * 10
      
      (0...numRows).each do |row|
        text = getItemText(row, col)
        max_width = [max_width, text.length * 9].max
      end
      
      max_width = [max_width, 400].min
      setColumnWidth(col, max_width + 15)
    end
  end
end