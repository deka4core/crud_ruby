# app/views/student_list_view.rb
require 'fox16'
include Fox
require_relative '../core/observer'

class StudentListView < FXMainWindow
  include Observer
  attr_accessor :controller
  
  COLUMNS = [
    { index: 0, title: "№", width: 60 },
    { index: 1, title: "Фамилия И.О.", width: 300 },
    { index: 2, title: "Git", width: 250 },
    { index: 3, title: "Контакт", width: 250 }
  ]
  
  def initialize(app, controller = nil)
    super(app, "Список студентов", width: 1300, height: 850)
    
    @controller = controller
    @items_per_page = 10 
    @current_page = 1
    @total_pages = 1
    
    puts "Создание интерфейса StudentListView..."
    setup_ui
    puts "Интерфейс создан"
    
    # Если контроллер передан, устанавливаем связь
    if @controller
      @controller.view = self
    end
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
    puts "Окно показано"
    
    # При открытии вызываем refresh_data у контроллера
    if @controller
      @controller.refresh_data
    end
  end
  
  # === Методы Observer ===
  def on_observable_event(event_type, data = nil)
    puts "View получил событие: #{event_type}"
    
    case event_type
    when :table_params
      if data.is_a?(Hash)
        set_table_params(data[:column_names], data[:whole_entities_count])
      end
    when :table_data
      if data.is_a?(Hash)
        set_table_data(data[:data_table])
      end
    when :sort_changed
      # Обновляем заголовки
      @current_sort_info = data
      update_column_headers(@current_sort_info)
    when :pagination_changed
      if data.is_a?(Hash)
        update_pagination_info(data[:current_page], data[:total_pages])
      end
    end
  end
  
  # Методы из ТЗ (Задание 1, пункт 3)
  def set_table_params(column_names, whole_entities_count)
    puts "set_table_params: колонки=#{column_names.inspect}, всего=#{whole_entities_count}"
    
    # Настраиваем заголовки
    if column_names.is_a?(Array) && column_names.size >= 3
      @table.setColumnText(1, column_names[0])
      @table.setColumnText(2, column_names[1])
      @table.setColumnText(3, column_names[2])
    end
    
    # Рассчитываем пагинацию
    if whole_entities_count > 0
      @total_pages = (whole_entities_count.to_f / @items_per_page).ceil
      @total_pages = 1 if @total_pages == 0
    else
      @total_pages = 1
    end
    
    update_pagination_info(1, @total_pages)
  end
  
  def set_table_data(data_table, sort_info = nil)
    puts "set_table_data: строк=#{data_table.rows_count}, колонок=#{data_table.columns_count}"
    
    return unless @table
    
    # Очищаем
    @table.setTableSize(0, 4)
    
    if data_table.rows_count > 0
      @table.setTableSize(data_table.rows_count, 4)
      
      data_table.rows_count.times do |row|
        4.times do |col|
          value = data_table.get_element(row, col)
          @table.setItemText(row, col, value.to_s) if value
        end
      end
    end

    update_column_headers(sort_info)
    
    adjust_column_widths
    update_buttons_state
  end

  def update_column_headers(sort_info)
    return unless @table
    
    COLUMNS.each do |col_info|
      header_text = col_info[:title]
      
      # Добавляем стрелочку если это столбец сортировки
      if sort_info && sort_info[:column] == col_info[:index]
        header_text += (sort_info['direction'] == :asc) ? " ▲" : " ▼"
      end
      
      @table.setColumnText(col_info[:index], header_text)
    end
  end
  
  def update_pagination_info(current_page, total_pages)
    puts "update_pagination_info: #{current_page}/#{total_pages}"
    
    return unless @page_label
    
    @current_page = current_page
    @total_pages = total_pages
    @page_label.text = "Страница #{current_page} из #{total_pages}"
    
    # Включаем/выключаем кнопки
    if @first_btn && @prev_btn && @next_btn && @last_btn
      @first_btn.enabled = current_page > 1
      @prev_btn.enabled = current_page > 1
      @next_btn.enabled = current_page < total_pages
      @last_btn.enabled = current_page < total_pages
    end
  end
  
  private
  
  def setup_ui
    # === 3 ВКЛАДКИ (Задание 0, пункт 2) ===
    create_tab_book
  end
  
  def create_tab_book
    tab_book = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # Вкладка 1: Список студентов
    tab1 = FXTabItem.new(tab_book, "📋 Список студентов", nil)
    tab1_container = FXVerticalFrame.new(tab_book, LAYOUT_FILL_X|LAYOUT_FILL_Y, padding: 10)
    create_main_content(tab1_container)
    
    # Вкладка 2: Пустая
    tab2 = FXTabItem.new(tab_book, "📊 Статистика", nil)
    tab2_container = FXVerticalFrame.new(tab_book, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    FXLabel.new(tab2_container, "Вторая вкладка - в разработке", nil, 
                JUSTIFY_CENTER_X|JUSTIFY_CENTER_Y|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # Вкладка 3: Пустая
    tab3 = FXTabItem.new(tab_book, "⚙️ Настройки", nil)
    tab3_container = FXVerticalFrame.new(tab_book, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    FXLabel.new(tab3_container, "Третья вкладка - в разработке", nil,
                JUSTIFY_CENTER_X|JUSTIFY_CENTER_Y|LAYOUT_FILL_X|LAYOUT_FILL_Y)
  end
  
  def create_main_content(parent)
    # === 1. ОБЛАСТЬ ФИЛЬТРАЦИИ (Задание 0, пункт 4,5) ===
    create_filter_panel(parent)
    
    FXHorizontalSeparator.new(parent, SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # === 2. ОБЛАСТЬ ТАБЛИЦЫ С ПАГИНАЦИЕЙ (Задание 0, пункт 6) ===
    create_table_panel(parent)
    
    FXHorizontalSeparator.new(parent, SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # === 3. ОБЛАСТЬ УПРАВЛЕНИЯ (Задание 0, пункт 7) ===
    create_control_panel(parent)
  end
  
  def create_filter_panel(parent)
    filter_frame = FXVerticalFrame.new(parent, LAYOUT_FILL_X, padding: 10)
    
    # Заголовок
    FXLabel.new(filter_frame, "ФИЛЬТРЫ ПОИСКА:", nil, JUSTIFY_LEFT).font = 
      FXFont.new(app, "Arial", 11, FONTWEIGHT_BOLD)
    
    # Часть 1: ФИО
    create_fio_filter(filter_frame)
    
    # Часть 2: Git (с комбобоксом как в ТЗ)
    create_git_filter(filter_frame)
    
    # Часть 3: Email
    create_email_filter(filter_frame)
    
    # Часть 4: Телефон
    create_phone_filter(filter_frame)
    
    # Часть 5: Telegram
    create_telegram_filter(filter_frame)
    
    # Кнопки фильтров
    create_filter_buttons(filter_frame)
  end
  
  def create_fio_filter(parent)
    frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 5)
    FXLabel.new(frame, "Фамилия И.О.:", nil, LAYOUT_CENTER_Y, :width => 150)
    @fio_field = FXTextField.new(frame, 40)
    @fio_field.tipText = "Введите часть ФИО для поиска"
  end
  
  def create_git_filter(parent)
    frame = FXVerticalFrame.new(parent, LAYOUT_FILL_X, padding: 5)
    
    # Заголовок
    title_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X)
    FXLabel.new(title_frame, "Git:", nil, LAYOUT_CENTER_Y, :width => 150)
    
    # Комбобокс с 3 альтернативами (как в ТЗ)
    combo_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X, padding: 5)
    FXLabel.new(combo_frame, "Наличие:", nil, LAYOUT_CENTER_Y, :width => 80)
    
    @git_combo = FXComboBox.new(combo_frame, 20, nil, 0, COMBOBOX_STATIC)
    @git_combo.appendItem("Не важно")
    @git_combo.appendItem("Да")
    @git_combo.appendItem("Нет")
    @git_combo.currentItem = 0
    
    # Поле для текста Git
    text_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X, padding: 5)
    FXLabel.new(text_frame, "Поиск в Git:", nil, LAYOUT_CENTER_Y, :width => 80)
    @git_text_field = FXTextField.new(text_frame, 30)
    @git_text_field.enabled = false
    
    # При изменении комбобокса
    @git_combo.connect(SEL_COMMAND) do
      @git_text_field.enabled = (@git_combo.currentItem == 1)  # Только для "Да"
    end
  end
  
  def create_email_filter(parent)
    frame = FXVerticalFrame.new(parent, LAYOUT_FILL_X, padding: 5)
    
    title_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X)
    FXLabel.new(title_frame, "Email:", nil, LAYOUT_CENTER_Y, :width => 150)
    
    combo_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X, padding: 5)
    FXLabel.new(combo_frame, "Наличие:", nil, LAYOUT_CENTER_Y, :width => 80)
    
    @email_combo = FXComboBox.new(combo_frame, 20, nil, 0, COMBOBOX_STATIC)
    @email_combo.appendItem("Не важно")
    @email_combo.appendItem("Да")
    @email_combo.appendItem("Нет")
    @email_combo.currentItem = 0
  end
  
  def create_phone_filter(parent)
    frame = FXVerticalFrame.new(parent, LAYOUT_FILL_X, padding: 5)
    
    title_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X)
    FXLabel.new(title_frame, "Телефон:", nil, LAYOUT_CENTER_Y, :width => 150)
    
    combo_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X, padding: 5)
    FXLabel.new(combo_frame, "Наличие:", nil, LAYOUT_CENTER_Y, :width => 80)
    
    @phone_combo = FXComboBox.new(combo_frame, 20, nil, 0, COMBOBOX_STATIC)
    @phone_combo.appendItem("Не важно")
    @phone_combo.appendItem("Да")
    @phone_combo.appendItem("Нет")
    @phone_combo.currentItem = 0
  end
  
  def create_telegram_filter(parent)
    frame = FXVerticalFrame.new(parent, LAYOUT_FILL_X, padding: 5)
    
    title_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X)
    FXLabel.new(title_frame, "Telegram:", nil, LAYOUT_CENTER_Y, :width => 150)
    
    combo_frame = FXHorizontalFrame.new(frame, LAYOUT_FILL_X, padding: 5)
    FXLabel.new(combo_frame, "Наличие:", nil, LAYOUT_CENTER_Y, :width => 80)
    
    @telegram_combo = FXComboBox.new(combo_frame, 20, nil, 0, COMBOBOX_STATIC)
    @telegram_combo.appendItem("Не важно")
    @telegram_combo.appendItem("Да")
    @telegram_combo.appendItem("Нет")
    @telegram_combo.currentItem = 0
  end
  
  def create_filter_buttons(parent)
    frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 10, hSpacing: 10)
    
    # Кнопка применения фильтров
    apply_btn = FXButton.new(frame, "Применить фильтры")
    apply_btn.connect(SEL_COMMAND) do
      FXMessageBox.information(self, MBOX_OK, "Информация", "Фильтры применены")
    end
    
    # Кнопка сброса фильтров (дополнительно)
    reset_btn = FXButton.new(frame, "Сбросить фильтры")
    reset_btn.connect(SEL_COMMAND) do
      reset_filters
      FXMessageBox.information(self, MBOX_OK, "Информация", "Фильтры сброшены")
    end
  end
  
  def reset_filters
    @fio_field.text = ""
    @git_combo.currentItem = 0
    @git_text_field.text = ""
    @git_text_field.enabled = false
    @email_combo.currentItem = 0
    @phone_combo.currentItem = 0
    @telegram_combo.currentItem = 0
  end
  
  def create_table_panel(parent)
    table_container = FXVerticalFrame.new(parent, LAYOUT_FILL_X | LAYOUT_FILL_Y, padding: 5)
    
    # Панель пагинации
    create_pagination_panel(table_container)
    
    # Таблица
    create_table(table_container)
  end
  
  def create_pagination_panel(parent)
    pagination_frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 10, hSpacing: 10)
    
    # Кнопки пагинации
    @first_btn = FXButton.new(pagination_frame, "⏮️ Первая")
    @prev_btn = FXButton.new(pagination_frame, "◀️ Пред.")
    
    @page_label = FXLabel.new(pagination_frame, "Страница 1 из 1", nil,
                              LAYOUT_CENTER_Y | FRAME_SUNKEN | FRAME_THICK,
                              :padLeft => 20, :padRight => 20)
    
    @next_btn = FXButton.new(pagination_frame, "След. ▶️")
    @last_btn = FXButton.new(pagination_frame, "Последняя ⏭️")
    
    # Начальное состояние
    @first_btn.enabled = false
    @prev_btn.enabled = false
    @next_btn.enabled = false
    @last_btn.enabled = false
    
    # Подсказки
    @first_btn.tipText = "Первая страница"
    @prev_btn.tipText = "Предыдущая страница"
    @next_btn.tipText = "Следующая страница"
    @last_btn.tipText = "Последняя страница"
    
    # Обработчики
    @first_btn.connect(SEL_COMMAND) do
      @controller.first_page if @controller
    end
    
    @prev_btn.connect(SEL_COMMAND) do
      @controller.prev_page if @controller
    end
    
    @next_btn.connect(SEL_COMMAND) do
      @controller.next_page if @controller
    end
    
    @last_btn.connect(SEL_COMMAND) do
      @controller.last_page if @controller
    end
  end
  
  def create_table(parent)
    table_frame = FXVerticalFrame.new(parent, LAYOUT_FILL_X | LAYOUT_FILL_Y, padding: 5)
    
    @table = FXTable.new(table_frame, 
      nil, 0, 
      TABLE_READONLY | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_COL_SIZABLE,
      :padding => 2)
    
    setup_table
  end
  
  def setup_table
    # Устанавливаем начальный размер
    @table.setTableSize(0, 4)
    
    # Заголовки
    COLUMNS.each do |col_info|
      @table.setColumnText(col_info[:index], col_info[:title])
      @table.setColumnWidth(col_info[:index], col_info[:width])
    end
    
    # Обработчик кликов по заголовкам для сортировки
    setup_column_header_handlers
    
    # Обработчики выделения строк
    @table.connect(SEL_SELECTED) do
      update_buttons_state
    end
    
    @table.connect(SEL_DESELECTED) do
      update_buttons_state
    end
  end
  
  def setup_column_header_handlers
    @columnHeader = @table.columnHeader
    
    @columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
      puts "Клик по заголовку столбца #{index}"
      
      # ТОЛЬКО для столбца 1 (Фамилия И.О.) как в ТЗ
      if index == 1 && @controller
        @controller.sort_by_column(index)
      elsif index != 1
        FXMessageBox.information(self, MBOX_OK, "Информация", 
          "Сортировка реализована только по столбцу 'Фамилия И.О.'")
      end
    end
  end
  
  def create_control_panel(parent)
    control_frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 10, hSpacing: 10)
    
    # Кнопки управления
    @add_btn = FXButton.new(control_frame, "➕ Добавить студента")
    @edit_btn = FXButton.new(control_frame, "✏️ Изменить")
    @delete_btn = FXButton.new(control_frame, "🗑️ Удалить")
    @refresh_btn = FXButton.new(control_frame, "🔄 Обновить")
    
    # Начальное состояние
    @edit_btn.enabled = false
    @delete_btn.enabled = false
    
    # Обработчики (заглушки)
    @add_btn.connect(SEL_COMMAND) do
      FXMessageBox.information(self, MBOX_OK, "Информация", "Добавление студента - в разработке")
    end
    
    @edit_btn.connect(SEL_COMMAND) do
      FXMessageBox.information(self, MBOX_OK, "Информация", "Редактирование - в разработке")
    end
    
    @delete_btn.connect(SEL_COMMAND) do
      FXMessageBox.information(self, MBOX_OK, "Информация", "Удаление - в разработке")
    end
    
    @refresh_btn.connect(SEL_COMMAND) do
      if @controller
        @controller.refresh_data
      end
    end
  end
  
  def get_selected_rows
    selected = []
    return selected unless @table
    
    (0...@table.numRows).each do |row|
      selected << row if @table.rowSelected?(row)
    end
    
    selected
  end
  
  def update_buttons_state
    return unless @edit_btn && @delete_btn
    
    selected_count = get_selected_rows.size
    
    if selected_count == 0
      @edit_btn.enabled = false
      @delete_btn.enabled = false
    elsif selected_count == 1
      @edit_btn.enabled = true
      @delete_btn.enabled = true
    else
      @edit_btn.enabled = false
      @delete_btn.enabled = true
    end
  end
  
  def adjust_column_widths
    return unless @table
    
    (0...@table.numColumns).each do |col|
      header_text = @table.getColumnText(col)
      max_width = header_text.length * 10 if header_text
      
      (0...@table.numRows).each do |row|
        text = @table.getItemText(row, col)
        if text && text.length > 0
          estimated_width = text.length * 8
          max_width = [max_width || 0, estimated_width].max
        end
      end
      
      min_width = COLUMNS.find { |c| c[:index] == col }[:width] rescue 100
      max_width = [max_width || min_width, min_width].max
      max_width = [max_width + 20, 500].min
      
      @table.setColumnWidth(col, max_width)
    end
  end
end