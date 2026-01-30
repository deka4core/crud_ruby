# app/views/student_list_view.rb

require_relative "../core/observer.rb"

class StudentListView < FXVerticalFrame
  include Observer
  
  attr_accessor :controller
  attr_reader :table, :model
  
  def initialize(parent, controller = nil)
    super(parent, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    
    @controller = controller
    @model = nil
    @selected_ids = []
    
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
         :page_changed, :filters_updated, :sort_updated  # Добавьте события!
      update_view
      update_buttons_state
    end
  end
  
  def update_view
    return unless @model
    
    # Получаем данные для текущей страницы
    students_short = @model.get_k_n_student_short_list(@model.current_page, @model.items_per_page)
    
    # Обновляем таблицу
    @table.clearItems if @table.numRows > 0
    @table.setTableSize(students_short.size, 4)
    
    students_short.each_with_index do |student, index|
      @table.setItemText(index, 0, student.id.to_s)
      @table.setItemText(index, 1, student.last_name_initials || "")
      @table.setItemText(index, 2, student.git || "")
      @table.setItemText(index, 3, student.contact || "")
    end
    
    # Обновляем информацию о пагинации
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
      TABLE_READONLY | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_COL_SIZABLE | TABLE_NO_COLSELECT)
    
    setup_table
    
    # Назначение обработчиков
    setup_event_handlers
  end
  
  def setup_table
    @table.setTableSize(0, 4)
    
    # Заголовки столбцов с поддержкой сортировки
    @table.setColumnText(0, "ID")
    @table.setColumnText(1, "Фамилия И.О.")
    @table.setColumnText(2, "Git")
    @table.setColumnText(3, "Контакт")
    
    # Ширина столбцов
    @table.setColumnWidth(0, 60)
    @table.setColumnWidth(1, 250)
    @table.setColumnWidth(2, 200)
    @table.setColumnWidth(3, 200)
    
    # Клик по заголовку для сортировки
    @table.columnHeader.connect(SEL_COMMAND) do |sender, sel, column_index|
      sort_by_column(column_index)
    end
  end
  
  def sort_by_column(column_index)
    if @controller && @controller.respond_to?(:sort_by_column)
      @controller.sort_by_column(column_index)
    end
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

    @table.connect(SEL_RIGHTBUTTONPRESS) do
      show_context_menu
    end
  end

  def show_context_menu
    menu = FXMenuPane.new(self)
    
    FXMenuCommand.new(menu, "Добавить студента").connect(SEL_COMMAND) do
      @controller.add_student if @controller
    end
    
    FXMenuSeparator.new(menu)
    
    FXMenuCommand.new(menu, "Изменить").connect(SEL_COMMAND) do
      selected_ids = get_selected_student_ids
      @controller.edit_student(selected_ids.first) if selected_ids.size == 1
    end
    
    FXMenuCommand.new(menu, "Удалить").connect(SEL_COMMAND) do
      selected_ids = get_selected_student_ids
      @controller.delete_students(selected_ids) if selected_ids.any?
    end
    
    menu.create
    menu.popup(nil, app.cursorX, app.cursorY)
  end
  
  def update_pagination_info
    return unless @model
    
    total = @model.filtered_students.size
    current = @model.current_page
    total_pages = @model.total_pages
    
    @page_label.text = "Страница #{current} из #{total_pages} | Всего: #{total}"
    
    @prev_button.enabled = (current > 1)
    @next_button.enabled = (current < total_pages)
  end
end