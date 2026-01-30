# app/views/main_window.rb
require 'fox16'
include Fox

require_relative 'student_list_view'
require_relative '../controllers/student_controller'
require_relative '../models/student_list_json'

class MainWindow < FXMainWindow
  def initialize(app)
    super(app, "Система управления студентами", width: 1000, height: 700)
    
    create_main_content
    
    self.connect(SEL_CLOSE) do
      # Сохраняем данные перед закрытием
      if @model && @model.respond_to?(:save_data)
        @model.save_data
      end
      getApp().exit
    end
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
    
    # Центрируем окно (правильный способ)
    self.x = (app.getRootWindow.width - self.width) / 2
    self.y = (app.getRootWindow.height - self.height) / 2
  end
  
  private
  
  def create_main_content
    main_container = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y)

    # Заголовок
    title_frame = FXHorizontalFrame.new(main_container, LAYOUT_FILL_X, padding: 10)
    title_label = FXLabel.new(title_frame, "Управление студентами", nil, 
                             JUSTIFY_CENTER_X | LAYOUT_FILL_X)
    title_label.font = FXFont.new(app, "Arial", 16, FONTWEIGHT_BOLD)
    
    # Разделитель
    FXHorizontalSeparator.new(main_container, SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # Создаем модель
    file_path = File.join(File.dirname(__FILE__), '..', '..', 'data', 'students.json')
    @model = StudentsListJSON.new(file_path)
    
    # Создаем представление
    student_list_view = StudentListView.new(main_container)
    
    # Создаем контроллер
    @controller = StudentController.new(student_list_view, @model)
  end

  private
  
  def create_main_content
    main_container = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y)

    # Заголовок
    title_frame = FXHorizontalFrame.new(main_container, LAYOUT_FILL_X, padding: 10)
    title_label = FXLabel.new(title_frame, "Управление студентами", nil, 
                             JUSTIFY_CENTER_X | LAYOUT_FILL_X)
    title_label.font = FXFont.new(app, "Arial", 16, FONTWEIGHT_BOLD)
    
    # Панель фильтров
    require_relative 'components/filter_panel'
    @filter_panel = FilterPanel.new(main_container)
    
    # Кнопки управления фильтрами
    filter_buttons = FXHorizontalFrame.new(main_container, LAYOUT_FILL_X, padding: 5)
    
    apply_filter_btn = FXButton.new(filter_buttons, "Применить фильтры")
    reset_filter_btn = FXButton.new(filter_buttons, "Сбросить фильтры")
    
    # Разделитель
    FXHorizontalSeparator.new(main_container, SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # Создаем модель
    file_path = File.join(File.dirname(__FILE__), '..', '..', 'data', 'students.json')
    @model = StudentsListJSON.new(file_path)
    
    # Создаем представление
    student_list_view = StudentListView.new(main_container)
    
    # Создаем контроллер
    @controller = StudentController.new(student_list_view, @model)
    
    # Обработчики фильтров
    apply_filter_btn.connect(SEL_COMMAND) do
      filters = @filter_panel.get_filters
      @model.update_filters(filters)
    end
    
    reset_filter_btn.connect(SEL_COMMAND) do
      @filter_panel.reset
      @model.update_filters({})
    end
  end
end