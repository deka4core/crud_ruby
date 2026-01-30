# app/views/student_list_view.rb
require 'fox16'
include Fox
require_relative '../core/observer'

class StudentListView < FXVerticalFrame
  include Observer
  
  attr_accessor :controller
  attr_reader :table, :model, :columnHeader
  
  def initialize(parent, controller = nil)
    super(parent, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    
    @controller = controller
    @model = nil
    @selected_ids = []
    @columnHeader = nil
    @rowHeader = nil
    
    puts "Создание StudentListView..."
    setup_ui
  end
  
  def set_model(model)
    @model&.remove_observer(self)
    @model = model
    @model&.add_observer(self)
    update_view
  end
  
  def on_observable_event(event_type, data = nil)
    case event_type
    when :student_added, :student_deleted, :student_updated, 
         :page_changed, :filters_updated, :sort_updated
      update_view
      update_buttons_state
    end
  end
  
  def update_view
    return unless @model
    
    # Обновляем заголовки
    update_column_headers
    
    # Получаем данные для текущей страницы
    students_short = @model.get_k_n_student_short_list(@model.current_page, @model.items_per_page)
    
    # Обновляем таблицу
    @table.clearItems if @table.numRows > 0
    @table.setTableSize(students_short.size, 4)

    @table.setColumnText(0, "ID")
    @table.setColumnText(1, "Фамилия И.О.")
    @table.setColumnText(2, "Git")
    @table.setColumnText(3, "Контакт")
    
    students_short.each_with_index do |student, index|
      @table.setRowText(index, (((@model.current_page - 1) * @model.items_per_page) + index + 1).to_s)
      @table.setItemText(index, 0, student.id.to_s)
      @table.setItemText(index, 1, student.last_name_initials || "")
      @table.setItemText(index, 2, student.git || "")
      @table.setItemText(index, 3, student.contact || "")
    end
    
    # Обновляем пагинацию
    update_pagination_info
  end
  
  def get_selected_student_ids
    selected_rows = []
    (0...@table.numRows).each do |row|
      selected_rows << row if @table.rowSelected?(row)
    end
    
    selected_ids = selected_rows.map do |row|
      id_text = @table.getItemText(row, 0)
      id_text.to_i if id_text && id_text.match?(/^\d+$/)
    end.compact
    
    @selected_ids = selected_ids
    selected_ids
  end
  
  def get_selected_student_count
    get_selected_student_ids.size
  end
  
  def update_buttons_state
    selected_count = get_selected_student_count
    
    case selected_count
    when 0
      @edit_button.disable
      @delete_button.disable
    when 1
      @edit_button.enable
      @delete_button.enable
    else
      @edit_button.disable
      @delete_button.enable
    end
  end
  
  def sort_by_column(column_index)
    if @controller && @controller.respond_to?(:sort_by_column)
      @controller.sort_by_column(column_index)
    end
  end
  
  def set_controller(controller)
    @controller = controller
  end
  
  private
  
  def setup_ui
    # Панель управления
    control_panel = FXHorizontalFrame.new(self, LAYOUT_FILL_X, padding: 10, hSpacing: 10)
    
    # Кнопки управления
    @add_button = FXButton.new(control_panel, "➕ Добавить")
    @edit_button = FXButton.new(control_panel, "✏️ Изменить")
    @delete_button = FXButton.new(control_panel, "🗑️ Удалить")
    @refresh_button = FXButton.new(control_panel, "🔄 Обновить")
    
    @edit_button.disable
    @delete_button.disable
    
    # Панель пагинации
    pagination_panel = FXHorizontalFrame.new(self, LAYOUT_FILL_X, padding: 10, hSpacing: 20)
    
    @prev_button = FXButton.new(pagination_panel, "◀ Предыдущая")
    @page_label = FXLabel.new(pagination_panel, "Страница 1 из 1", nil, LAYOUT_CENTER_Y)
    @next_button = FXButton.new(pagination_panel, "Следующая ▶")
    
    # Таблица
    table_frame = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y, padding: 5)
    @table = FXTable.new(table_frame, 
      nil, 0, 
      TABLE_READONLY | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_COL_SIZABLE)
    
    setup_table
    setup_event_handlers
  end
  
  def setup_table
    # Устанавливаем размер таблицы
    @table.setTableSize(0, 4)
    
    # Устанавливаем заголовки колонок
    @table.setColumnText(0, "ID")
    @table.setColumnText(1, "Фамилия И.О.")
    @table.setColumnText(2, "Git")
    @table.setColumnText(3, "Контакт")
    
    # Устанавливаем ширину колонок
    @table.setColumnWidth(0, 60)
    @table.setColumnWidth(1, 250)
    @table.setColumnWidth(2, 200)
    @table.setColumnWidth(3, 200)
    
    # 1. Верхние заголовки - сортировка (ТОЧНО как у вас!)
    @columnHeader = @table.columnHeader
    
    # Отладка
    puts "Заголовок колонок: #{@columnHeader ? 'есть' : 'нет'}"
    puts "Колонок в заголовке: #{@columnHeader.numItems if @columnHeader}"
    
    @columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
      puts "Клик по заголовку колонки: #{index}"
      
      # Разрешаем сортировку только по ID (0) и ФИО (1)
      if index == 0 || index == 1
        if @controller && @controller.respond_to?(:sort_by_column)
          @controller.sort_by_column(index)
        else
          puts "Контроллер не доступен для сортировки"
        end
      else
        puts "Сортировка по колонке #{index} недоступна"
      end
    end
    
    # 2. ЛЕВЫЕ заголовки - выделение (опционально)
    # @rowHeader = @table.rowHeader
    # @rowHeader.connect(SEL_COMMAND) do |sender, sel, index|
    #   @table.killSelection
    #   @table.selectRow(index, true)
    #   update_buttons_state
    # end
    
    # Обновляем заголовки сразу
    update_column_headers
  end
  
  def setup_column_click_handler
    # Подключаем обработчик команд заголовков колонок
    @table.connect(Fox::SEL_COMMAND, Fox::FXTable::ID_COLUMN_HEADER) do |sender, sel, ptr|
      # ptr - это указатель на FXEvent, нужно получить индекс колонки
      event = Fox::FXEvent.ptr(ptr)
      
      if event
        # Получаем координаты клика
        column_index = @table.getColumnAtX(event.win_x)
        
        puts "Клик по заголовку колонки: #{column_index}"
        
        # Разрешаем сортировку только по ID (0) и ФИО (1)
        if column_index == 0 || column_index == 1
          sort_by_column(column_index)
        else
          puts "Сортировка по столбцу #{column_index} недоступна"
        end
      end
    end
  end
  
  def update_column_headers
    return unless @model && @columnHeader
    
    puts "Обновление заголовков. Текущая сортировка: колонка=#{@model.sort_column}, направление=#{@model.sort_direction}"
    
    # Базовые названия колонок
    column_names = ["ID", "Фамилия И.О.", "Git", "Контакт"]
    
    # Добавляем стрелочку для текущей колонки сортировки
    if @model.sort_column == 0 || @model.sort_column == 1
      arrow = (@model.sort_direction == :asc) ? " ▲" : " ▼"
      column_names[@model.sort_column] += arrow
      
      # Устанавливаем стрелку через API FXHeader
      arrow_dir = (@model.sort_direction == :asc) ? Fox::TRUE : Fox::FALSE
      @columnHeader.setArrowDir(@model.sort_column, arrow_dir)
    end
    
    # Сбрасываем стрелки для других колонок
    (0..3).each do |index|
      if index != @model.sort_column && (index == 0 || index == 1)
        @columnHeader.setArrowDir(index, Fox::MAYBE)
      end
    end
    
    # Устанавливаем текст заголовков
    column_names.each_with_index do |name, index|
      @table.setColumnText(index, name)
    end
    
    puts "Заголовки обновлены"
  end
    
  def setup_event_handlers
    # Кнопки управления
    @add_button.connect(SEL_COMMAND) do
      if @controller && @controller.respond_to?(:add_student)
        @controller.add_student
      end
    end
    
    @edit_button.connect(SEL_COMMAND) do
      if @controller && @controller.respond_to?(:edit_student)
        selected_ids = get_selected_student_ids
        @controller.edit_student(selected_ids.first) if selected_ids.size == 1
      end
    end
    
    @delete_button.connect(SEL_COMMAND) do
      if @controller && @controller.respond_to?(:delete_students)
        selected_ids = get_selected_student_ids
        @controller.delete_students(selected_ids) if selected_ids.any?
      end
    end
    
    @refresh_button.connect(SEL_COMMAND) do
      update_view
    end
    
    # Пагинация
    @prev_button.connect(SEL_COMMAND) do
      @model.prev_page if @model
    end
    
    @next_button.connect(SEL_COMMAND) do
      @model.next_page if @model
    end
    
    # Выделение строк в таблице
    @table.connect(SEL_SELECTED) do
      update_buttons_state
    end
    
    @table.connect(SEL_DESELECTED) do
      update_buttons_state
    end
    
    # Двойной клик для редактирования
    @table.connect(SEL_DOUBLECLICKED) do
      selected_ids = get_selected_student_ids
      if selected_ids.size == 1 && @controller && @controller.respond_to?(:edit_student)
        @controller.edit_student(selected_ids.first)
      end
    end
  end
  
  def update_pagination_info
    return unless @model
    
    total = @model.filtered_students.size
    current = @model.current_page
    total_pages = @model.total_pages
    
    # Добавляем информацию о сортировке
    sort_info = ""
    if @model.sort_column == 0
      direction = @model.sort_direction == :asc ? "↑" : "↓"
      sort_info = " | Сортировка: ID #{direction}"
    elsif @model.sort_column == 1
      direction = @model.sort_direction == :asc ? "↑" : "↓"
      sort_info = " | Сортировка: ФИО #{direction}"
    end
    
    @page_label.text = "Страница #{current} из #{total_pages} | Всего: #{total}#{sort_info}"
    
    @prev_button.enabled = (current > 1)
    @next_button.enabled = (current < total_pages)
  end
end