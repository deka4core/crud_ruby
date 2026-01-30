# app/views/main_window.rb
require 'fox16'
include Fox

require_relative 'student_list_view'

class MainWindow < FXMainWindow
  attr_reader :controller, :view
  
  def initialize(app)
    super(app, "Система управления студентами", width: 1000, height: 700)
    
    create_main_content
    
    self.connect(SEL_CLOSE) do
      if @controller && @controller.model.respond_to?(:save_data)
        @controller.model.save_data
      end
      getApp().exit
    end
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
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
    
    # Создаем View
    @view = StudentListView.new(main_container)
    
    # Разделитель перед нижней панелью
    FXHorizontalSeparator.new(main_container, SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # Нижняя панель со статусом
    status_frame = FXHorizontalFrame.new(main_container, LAYOUT_FILL_X, padding: 5)
    @status_label = FXLabel.new(status_frame, "Готово", nil, JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    FXHorizontalFrame.new(status_frame, LAYOUT_FILL_X)
  end
  
  def update_status(message)
    @status_label.text = message if @status_label
  end
end