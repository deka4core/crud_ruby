# app/views/main_window.rb
require 'fox16'
include Fox
require 'fileutils'
require_relative '../core/observable'

require_relative '../models/student_list_json'
require_relative '../controllers/student_controller'
require_relative 'components/student_table'
require_relative 'components/filter_panel'
require_relative 'components/pagination_panel'

class MainWindow < FXMainWindow
  include Observable
  
  attr_reader :student_list, :student_table, :controller, 
              :filter_panel, :pagination_panel
  
  def initialize(app)
    super(app, "Управление студентами", width: 1400, height: 900)
    
    initialize_student_list
    setup_ui
    setup_controllers
    setup_event_handlers
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
    notify_observers(:view_ready)
  end
  
  # Метод наблюдателя для обработки событий от компонентов
  def on_observable_event(event_type, data = nil, observable = nil)
    case event_type
    when :selection_changed
      notify_observers(:selection_changed, data)
    when :student_double_clicked
      notify_observers(:student_double_clicked, data)
    when :page_changed
      notify_observers(:page_changed, data)
    when :sort_column
      notify_observers(:sort_column, data)
    end
  end
  
  # Методы для контроллера
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
  
  def table
    @student_table
  end

  def pagination
    @pagination
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
      notify_observers(:reset_filters)
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
    
    # Создаем таблицу и регистрируем MainWindow как наблюдатель
    @student_table = StudentTable.new(students_frame)
    @student_table.add_observer(self)
    
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
    @pagination = PaginationPanel.new(parent)
    @pagination.add_observer(self)
  end
  
  def setup_event_handlers
    @add_btn.connect(SEL_COMMAND) { @controller.add_student }
    @edit_btn.connect(SEL_COMMAND) { @controller.edit_student }
    @delete_btn.connect(SEL_COMMAND) { @controller.delete_students }
    @refresh_btn.connect(SEL_COMMAND) do
      filters = @filter_panel.get_filters
      notify_observers(:apply_filters, filters)
    end
    
    self.connect(SEL_CLOSE) do
      @student_list.save_data
      getApp().exit
    end
  end
  
  def add_test_students
    require_relative '../models/student'
    
    test_students = []
    
    first_names = ["Иван", "Петр", "Мария", "Анна", "Сергей", "Ольга", "Алексей", "Екатерина", "Дмитрий", "Наталья"]
    last_names = ["Иванов", "Петров", "Сидоров", "Смирнов", "Кузнецов", "Попов", "Васильев", "Новиков", "Федоров", "Морозов"]
    patronymics = ["Иванович", "Петрович", "Сергеевич", "Александрович", "Дмитриевич", 
                   "Алексеевна", "Сергеевна", "Александровна", "Дмитриевна", "Владимировна"]
    
    45.times do |i|
      first_name = first_names[i % first_names.size]
      last_name = last_names[i % last_names.size]
      patronymic = patronymics[i % patronymics.size]
      
      git = case i % 4
            when 0 then "https://github.com/user#{i}"
            when 1 then "https://gitlab.com/dev#{i}"
            when 2 then nil
            else "https://github.com/projects/repo#{i}"
            end
      
      email = case i % 5
              when 0 then "student#{i}@mail.ru"
              when 1 then "user#{i}@gmail.com"
              when 2 then "test#{i}@yandex.ru"
              else nil
              end
      
      phone = case i % 6
              when 0 then "+79161234567"
              when 1 then "89161234567"
              when 2 then "+7 916 123-45-67"
              when 3 then "8(916)123-45-67"
              when 4 then "+7-916-123-45-67"
              else nil
              end
      
      telegram = case i % 7
                 when 0 then "@student#{i.to_s.rjust(5, '0')[0,5]}"
                 when 1 then "@dev#{i.to_s.rjust(5, '0')[0,5]}"
                 when 2 then "@coder#{i.to_s.rjust(4, '0')[0,4]}"
                 else nil
                 end
      
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
      rescue => e
        puts "❌ Ошибка при создании студента #{i+1}: #{e.message}"
      end
    end
    
    begin
      test_students << Student.new(
        first_name: "Без",
        last_name: "Контактов", 
        patronymic: "Никаких",
        git: nil,
        email: nil,
        phone: nil,
        telegram: nil
      )
      
      test_students << Student.new(
        first_name: "Со",
        last_name: "Всемиконтактами",
        patronymic: "Всеволод",
        git: "https://github.com/fullstack/project",
        email: "full@example.com",
        phone: "+7 916 123-45-67",
        telegram: "@fullcontact123"
      )
      
      test_students << Student.new(
        first_name: "Поиск",
        last_name: "Тестовый",
        patronymic: "Искомый", 
        git: "https://gitlab.com/search/test",
        email: "search@test.ru",
        phone: "8(916)999-88-77",
        telegram: "@searchme56789"
      )
    rescue => e
      puts "❌ Ошибка в специальных кейсах: #{e.message}"
    end
    
    test_students.each { |student| @student_list.add_student(student) }
  end
end