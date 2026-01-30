# app/views/student_list_view.rb
require 'fox16'
include Fox

class StudentListView < FXMainWindow
  attr_accessor :controller
  
  def initialize(app)
    super(app, "Список студентов", width: 1000, height: 700)
    
    @controller = nil
    @items_per_page = 10
    
    puts "Создание интерфейса..."
    setup_ui
    puts "Интерфейс создан"
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
    puts "Окно показано"
  end
  
  # Метод для обновления данных таблицы
  def set_table_data(data_table)
    puts "=== set_table_data вызван ==="
    
    return unless @table
    
    if data_table.nil?
      puts "Ошибка: data_table равен nil"
      clear_table
      return
    end
    
    puts "Количество строк в data_table: #{data_table.rows_count}"
    puts "Количество колонок в data_table: #{data_table.columns_count}"
    
    # Очищаем таблицу
    clear_table
    
    # Устанавливаем размер таблицы
    rows_to_fill = [data_table.rows_count, @items_per_page].min
    puts "Будет заполнено строк: #{rows_to_fill}"
    
    @table.setTableSize(rows_to_fill, 4)
    puts "Размер таблицы установлен: #{rows_to_fill} x 4"
    
    # Заполняем данные, только если есть что заполнять
    if rows_to_fill > 0
      puts "Заполняем таблицу данными..."
      rows_to_fill.times do |row|
        4.times do |col|
          value = data_table.get_element(row, col)
          if value
            @table.setItemText(row, col, value.to_s)
          end
        end
      end
    else
      puts "Нет данных для заполнения"
      # Устанавливаем таблицу с 0 строк
      @table.setTableSize(0, 4)
    end
    
    adjust_column_widths
    puts "=== set_table_data завершен ==="
  end
  
  # Метод для обновления информации о пагинации
  def update_pagination_info(current_page, total_pages)
    puts "update_pagination_info: #{current_page}/#{total_pages}"
    
    return unless @page_label && @prev_btn && @next_btn
    
    @page_label.text = "Страница #{current_page} из #{total_pages}"
    
    # Включаем/выключаем кнопки
    @first_btn.enabled = current_page > 1
    @prev_btn.enabled = current_page > 1
    @next_btn.enabled = current_page < total_pages
    @last_btn.enabled = current_page < total_pages
  end
  
  private
  
  def setup_ui
    # Основной контейнер
    main_frame = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y, padding: 10)
    
    # Заголовок
    title_frame = FXHorizontalFrame.new(main_frame, LAYOUT_FILL_X, padding: 10)
    title_label = FXLabel.new(title_frame, "Список студентов", nil, 
                             JUSTIFY_CENTER_X | LAYOUT_FILL_X)
    title_label.font = FXFont.new(app, "Arial", 14, FONTWEIGHT_BOLD)
    
    # Разделитель
    FXHorizontalSeparator.new(main_frame, SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # Панель управления
    create_control_panel(main_frame)
    
    # Панель пагинации
    create_pagination_panel(main_frame)
    
    # Таблица
    create_table(main_frame)
    
    # Панель статуса
    create_status_panel(main_frame)
  end
  
  def create_control_panel(parent)
    control_frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 10, hSpacing: 10)
    
    # Кнопки управления
    @add_btn = FXButton.new(control_frame, "Добавить студента")
    @edit_btn = FXButton.new(control_frame, "Изменить")
    @delete_btn = FXButton.new(control_frame, "Удалить")
    @refresh_btn = FXButton.new(control_frame, "Обновить")
    
    # Начальное состояние кнопок
    @edit_btn.enabled = false
    @delete_btn.enabled = false
    
    # Привязка событий
    @add_btn.connect(SEL_COMMAND) do
      FXMessageBox.information(self, MBOX_OK, "Информация", "Добавление - в разработке")
    end
    
    @edit_btn.connect(SEL_COMMAND) do
      selected = get_selected_rows
      if selected.size == 1
        FXMessageBox.information(self, MBOX_OK, "Информация", "Редактирование строки #{selected.first + 1}")
      end
    end
    
    @delete_btn.connect(SEL_COMMAND) do
      selected = get_selected_rows
      if selected.any?
        FXMessageBox.information(self, MBOX_OK, "Информация", "Удаление #{selected.size} записей")
      end
    end
    
    @refresh_btn.connect(SEL_COMMAND) do
      if @controller
        puts "Кнопка Обновить нажата"
        @controller.refresh_data
      else
        puts "Контроллер не установлен!"
      end
    end
  end
  
  def create_pagination_panel(parent)
    pagination_frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 10, hSpacing: 10)
    
    # Кнопки пагинации
    @first_btn = FXButton.new(pagination_frame, "<<")
    @prev_btn = FXButton.new(pagination_frame, "<")
    
    @page_label = FXLabel.new(pagination_frame, "Страница 1 из 1", nil, 
                              LAYOUT_CENTER_Y | FRAME_SUNKEN | FRAME_THICK,
                              :padLeft => 20, :padRight => 20)
    
    @next_btn = FXButton.new(pagination_frame, ">")
    @last_btn = FXButton.new(pagination_frame, ">>")
    
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
    
    # Привязка событий пагинации
    @first_btn.connect(SEL_COMMAND) do 
      puts "Кнопка << нажата"
      @controller.first_page if @controller
    end
    
    @prev_btn.connect(SEL_COMMAND) do 
      puts "Кнопка < нажата"
      @controller.prev_page if @controller
    end
    
    @next_btn.connect(SEL_COMMAND) do 
      puts "Кнопка > нажата"
      @controller.next_page if @controller
    end
    
    @last_btn.connect(SEL_COMMAND) do 
      puts "Кнопка >> нажата"
      @controller.last_page if @controller
    end
  end
  
  def create_table(parent)
    table_frame = FXVerticalFrame.new(parent, LAYOUT_FILL_X | LAYOUT_FILL_Y, padding: 5)
    
    # Создаем таблицу
    @table = FXTable.new(table_frame, 
      nil, 0, 
      TABLE_READONLY | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_COL_SIZABLE,
      :padding => 2)
    
    setup_table
  end
  
  def create_status_panel(parent)
    status_frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 5)
    @status_label = FXLabel.new(status_frame, "Готово. Данные загружаются...", nil, 
                               JUSTIFY_LEFT | LAYOUT_CENTER_Y)
  end
  
  def setup_table
    puts "Настройка таблицы..."
    
    # Устанавливаем начальный размер
    @table.setTableSize(0, 4)  # Начинаем с 0 строк!
    puts "Размер таблицы: 0 x 4"
    
    # Заголовки столбцов
    @table.setColumnText(0, "№")
    @table.setColumnText(1, "Фамилия И.О.")
    @table.setColumnText(2, "Git")
    @table.setColumnText(3, "Контакт")
    
    # Настраиваем ширину столбцов
    @table.setColumnWidth(0, 60)
    @table.setColumnWidth(1, 250)
    @table.setColumnWidth(2, 200)
    @table.setColumnWidth(3, 250)
    
    # Обработчики событий таблицы
    @table.connect(SEL_SELECTED) do
      update_buttons_state
      update_status
    end
    
    @table.connect(SEL_DESELECTED) do
      update_buttons_state
      update_status
    end
    
    puts "Таблица настроена"
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
    return unless @edit_btn && @delete_btn && @table
    
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
  
  def update_status
    selected = get_selected_rows
    if selected.empty?
      @status_label.text = "Готово. Выберите строку для редактирования."
    elsif selected.size == 1
      @status_label.text = "Выбрана 1 строка. Можно редактировать или удалить."
    else
      @status_label.text = "Выбрано #{selected.size} строк. Можно удалить."
    end
  end
  
  def clear_table
    puts "Очистка таблицы..."
    return unless @table
    
    current_rows = @table.numRows
    current_cols = @table.numColumns
    
    puts "Текущий размер таблицы: #{current_rows} x #{current_cols}"
    
    # Очищаем только существующие ячейки
    if current_rows > 0 && current_cols > 0
      (0...current_rows).each do |row|
        (0...current_cols).each do |col|
          @table.setItemText(row, col, "")
        end
      end
      puts "Таблица очищена (#{current_rows} x #{current_cols})"
    else
      puts "Таблица уже пустая, очистка не требуется"
    end
  end
  
  def adjust_column_widths
    return unless @table
    
    (0...@table.numColumns).each do |col|
      max_width = @table.getColumnText(col).length * 10
      
      (0...@table.numRows).each do |row|
        text = @table.getItemText(row, col)
        if text && text.length > 0
          estimated_width = text.length * 8
          max_width = [max_width, estimated_width].max
        end
      end
      
      # Ограничиваем максимальную ширину
      max_width = [max_width + 20, 500].min
      @table.setColumnWidth(col, max_width)
    end
  end
end