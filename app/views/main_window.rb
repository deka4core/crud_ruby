# app/views/main_window.rb
require 'fox16'
include Fox
require 'fileutils'

require_relative '../models/student_list_json'
require_relative '../controllers/student_controller'
require_relative 'components/student_table'
require_relative 'components/filter_panel'
require_relative 'components/pagination_panel'

class MainWindow < FXMainWindow
  attr_reader :student_list, :student_table, :controller, 
              :filter_panel, :pagination_panel
  
  def initialize(app)
    super(app, "Управление студентами", width: 1400, height: 900)
    
    initialize_student_list
    setup_controllers
    setup_ui
    setup_event_handlers
    refresh_table
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
    @controller.apply_filters
  end
  
  def refresh_table
    @controller.apply_filters if @controller
  end
  
  def update_buttons_state(selected_count)
    return unless @edit_btn && @delete_btn
    
    case selected_count
    when 0
      @edit_btn.disable
      @delete_btn.disable
    when 1
      @edit_btn.enable
      @delete_btn.enable
    else
      @edit_btn.disable
      @delete_btn.enable
    end
  end

  def display_data(data_list, total_count, current_page)
    return unless @student_table && @pagination
    
    @student_table.update_table(data_list)
    
    @pagination.update_info(total_count)
    @pagination.current_page = current_page
    
    if @count_label
      @count_label.text = "Всего: #{total_count}"
    end
  end
  
  private
  
  def initialize_student_list
    data_dir = File.join(File.dirname(__FILE__), '..', '..', 'data')
    json_file = File.join(data_dir, 'students.json')
    
    FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
    
    unless File.exist?(json_file) && !File.zero?(json_file)
      File.write(json_file, "[]")
    end
    
    @student_list = StudentsListJSON.new(json_file)
    
    if @student_list.get_student_short_count == 0
      add_test_students
      @student_list.save_data
    end
  end
  
  def setup_controllers
    @controller = StudentController.new(self, @student_list)
  end
  
  def setup_ui
    main_container = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    
    setup_filter_panel(main_container)
    setup_control_panel(main_container)
    setup_table_area(main_container)
    setup_pagination_panel(main_container)
  end
  
  def setup_filter_panel(parent)
    @filter_panel = FilterPanel.new(parent)
    
    reset_frame = FXHorizontalFrame.new(@filter_panel, LAYOUT_FILL_X)
    FXHorizontalFrame.new(reset_frame, LAYOUT_FILL_X)
    
    reset_btn = FXButton.new(reset_frame, "Сбросить фильтры")
    reset_btn.connect(SEL_COMMAND) do
      @filter_panel.reset
      @controller.apply_filters
    end
  end
  
  def setup_control_panel(parent)
    control_panel = FXHorizontalFrame.new(parent, 
      LAYOUT_FILL_X | FRAME_RAISED)
    
    @add_btn = FXButton.new(control_panel, "➕ Добавить")
    @edit_btn = FXButton.new(control_panel, "✏️ Изменить")
    @delete_btn = FXButton.new(control_panel, "🗑️ Удалить")
    @refresh_btn = FXButton.new(control_panel, "🔍 Применить фильтры")
    
    @edit_btn.disable
    @delete_btn.disable
    
    FXHorizontalFrame.new(control_panel, LAYOUT_FILL_X)
    
    student_count = @student_list.get_student_short_count
    @count_label = FXLabel.new(control_panel, "Всего: #{student_count}")
  end
  
  def setup_table_area(parent)
    @tab_book = FXTabBook.new(parent, nil, 0, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    
    FXTabItem.new(@tab_book, "Студенты", nil)
    students_frame = FXVerticalFrame.new(@tab_book, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    @student_table = StudentTable.new(students_frame, @controller)
    
    FXTabItem.new(@tab_book, "Вкладка 2", nil)
    tab2_frame = FXVerticalFrame.new(@tab_book, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    FXLabel.new(tab2_frame, "Содержимое второй вкладки\n\nЭта вкладка будет реализована в будущих лабораторных работах.", 
                nil, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    
    FXTabItem.new(@tab_book, "Вкладка 3", nil)
    tab3_frame = FXVerticalFrame.new(@tab_book, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    FXLabel.new(tab3_frame, "Содержимое третьей вкладки\n\nЭта вкладка будет реализована в будущих лабораторных работах.", 
                nil, LAYOUT_FILL_X | LAYOUT_FILL_Y)
  end
  
  def setup_pagination_panel(parent)
    @pagination = PaginationPanel.new(parent, @controller)
  end
  
  def setup_event_handlers
    @add_btn.connect(SEL_COMMAND) { @controller.add_student }
    @edit_btn.connect(SEL_COMMAND) { @controller.edit_student }
    @delete_btn.connect(SEL_COMMAND) { @controller.delete_students }
    @refresh_btn.connect(SEL_COMMAND) { @controller.apply_filters }
    
    self.connect(SEL_CLOSE) do
      @student_list.save_data
      getApp().exit
    end
  end
  
  def add_test_students
  require_relative '../models/student'
  
  test_students = []
  
  # Массивы для генерации - УЧИТЫВАЕМ valid_name? (только первая буква заглавная)
  first_names = ["Иван", "Петр", "Мария", "Анна", "Сергей", "Ольга", "Алексей", "Екатерина", "Дмитрий", "Наталья"]
  last_names = ["Иванов", "Петров", "Сидоров", "Смирнов", "Кузнецов", "Попов", "Васильев", "Новиков", "Федоров", "Морозов"]
  patronymics = ["Иванович", "Петрович", "Сергеевич", "Александрович", "Дмитриевич", 
                 "Алексеевна", "Сергеевна", "Александровна", "Дмитриевна", "Владимировна"]
  
  # Генерируем 45 студентов
  45.times do |i|
    first_name = first_names[i % first_names.size]
    last_name = last_names[i % last_names.size]
    patronymic = patronymics[i % patronymics.size]
    
    # Git - УЧИТЫВАЕМ valid_git? (только github.com или gitlab.com)
    git = case i % 4
          when 0 then "https://github.com/user#{i}"
          when 1 then "https://gitlab.com/dev#{i}"
          when 2 then nil
          else "https://github.com/projects/repo#{i}"  # С подпапкой
          end
    
    # Email - УЧИТЫВАЕМ valid_email?
    email = case i % 5
            when 0 then "student#{i}@mail.ru"
            when 1 then "user#{i}@gmail.com"
            when 2 then "test#{i}@yandex.ru"
            else nil
            end
    
    # Phone - КРИТИЧНО! УЧИТЫВАЕМ valid_phone?:
    # ^(\+7|8)[\s\(\-]?\d{3}[\s\)\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}$
    # Формат: (+7|8) + 3 цифры + 3 цифры + 2 цифры + 2 цифры
    # Всего: 1(+7) или 1(8) + 10 цифр = 11-12 символов
    phone = case i % 6
            when 0 then "+79161234567"      # Без разделителей: +7 916 123-45-67
            when 1 then "89161234567"       # Без разделителей: 8 916 123-45-67
            when 2 then "+7 916 123-45-67"  # С пробелами и дефисами
            when 3 then "8(916)123-45-67"   # Со скобками и дефисами
            when 4 then "+7-916-123-45-67"  # Только дефисы
            else nil  # Нет телефона
            end
    
    # Telegram - УЧИТЫВАЕМ valid_telegram? (^@[a-zA-Z0-9_]{5,}$)
    telegram = case i % 7
               when 0 then "@student#{i.to_s.rjust(5, '0')[0,5]}"  # @student00000 - @student00044
               when 1 then "@dev#{i.to_s.rjust(5, '0')[0,5]}"      # @dev00000 - @dev00044
               when 2 then "@coder#{i.to_s.rjust(4, '0')[0,4]}"    # @coder0000 - @coder0044
               else nil
               end
    
    # Создаем студента
    begin
      test_students << Student.new(
        first_name: first_name,
        last_name: last_name,
        patronymic: patronymic,
        git: git,
        email: email,
        phone: phone,
        telegram: telegram
      )
      puts "✅ Создан студент #{i+1}: #{last_name} #{first_name[0]}."
    rescue => e
      puts "❌ Ошибка при создании студента #{i+1}: #{e.message}"
      puts "   Параметры: phone='#{phone}', telegram='#{telegram}'"
    end
  end
  
  # Специальные кейсы
  begin
    # 1. Без контактов
    test_students << Student.new(
      first_name: "Без",
      last_name: "Контактов", 
      patronymic: "Никаких",
      git: nil,
      email: nil,
      phone: nil,
      telegram: nil
    )
    puts "✅ Создан студент 'Без Контактов'"
    
    # 2. Со всеми контактами (ИДЕАЛЬНЫЕ ФОРМАТЫ)
    test_students << Student.new(
      first_name: "Со",
      last_name: "Всемиконтактами",  # Исправлено: первая заглавная, остальные строчные
      patronymic: "Всеволод",
      git: "https://github.com/fullstack/project",
      email: "full@example.com",
      phone: "+7 916 123-45-67",  # Идеальный формат с пробелами и дефисами
      telegram: "@fullcontact123"  # 13 символов после @
    )
    puts "✅ Создан студент 'Со Всемиконтактами'"
    
    # 3. Для поиска
    test_students << Student.new(
      first_name: "Поиск",
      last_name: "Тестовый",
      patronymic: "Искомый", 
      git: "https://gitlab.com/search/test",
      email: "search@test.ru",
      phone: "8(916)999-88-77",  # Другой валидный формат
      telegram: "@searchme56789"  # 11 символов после @
    )
    puts "✅ Создан студент 'Поиск Тестовый'"
  rescue => e
    puts "❌ Ошибка в специальных кейсах: #{e.message}"
  end
  
  puts "\n📊 Итого: создано #{test_students.size} студентов"
  
  # Добавляем
  test_students.each { |student| @student_list.add_student(student) }
  
  test_students.size
end
  
  def table
    @student_table
  end

  def pagination
    @pagination
  end
end