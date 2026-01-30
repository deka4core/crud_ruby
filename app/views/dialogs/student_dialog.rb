# app/views/dialogs/student_dialog.rb
require 'fox16'
include Fox

class StudentDialog < FXDialogBox
  def initialize(parent, student = nil, title = nil)
    title ||= student ? "Редактирование студента" : "Добавление студента"
    super(parent, title, DECOR_TITLE | DECOR_BORDER | DECOR_CLOSE)
    
    @student = student
    @student_data = nil
    
    setup_ui
    load_student_data if student
    
    # Устанавливаем минимальный размер
    self.width = 500
    self.height = 400
  end
  
  def execute
    show(PLACEMENT_SCREEN)
    getApp().runModalFor(self)
    @student_data
  end
  
  def student_data
    @student_data
  end
  
  private
  
  def setup_ui
    # Основной контейнер с отступами
    main_frame = FXVerticalFrame.new(self, 
      LAYOUT_FILL_X | LAYOUT_FILL_Y,
      :padLeft => 10, :padRight => 10, :padTop => 10, :padBottom => 10)
    
    # Заголовок
    title = @student ? "Редактирование данных студента" : "Введите данные нового студента"
    FXLabel.new(main_frame, title, nil, 
      JUSTIFY_LEFT | LAYOUT_FILL_X | LAYOUT_TOP)
    
    # Разделитель
    FXHorizontalSeparator.new(main_frame, 
      SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # Поля формы в матрице
    setup_form_fields(main_frame)
    
    # Горизонтальный разделитель
    FXHorizontalSeparator.new(main_frame, 
      SEPARATOR_GROOVE | LAYOUT_FILL_X)
    
    # Кнопки внизу
    setup_buttons(main_frame)
  end
  
  def setup_form_fields(parent)
    # Используем матрицу для выравнивания полей
    fields_frame = FXMatrix.new(parent, 2, 
      MATRIX_BY_COLUMNS | LAYOUT_FILL_X,
      :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)
    
    # Фамилия (обязательное)
    FXLabel.new(fields_frame, "Фамилия:*", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @last_name_input = FXTextField.new(fields_frame, 30, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Имя (обязательное)
    FXLabel.new(fields_frame, "Имя:*", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @first_name_input = FXTextField.new(fields_frame, 30, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Отчество (необязательное)
    FXLabel.new(fields_frame, "Отчество:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @patronymic_input = FXTextField.new(fields_frame, 30, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Git
    FXLabel.new(fields_frame, "Git URL:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @git_input = FXTextField.new(fields_frame, 40, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Email
    FXLabel.new(fields_frame, "Email:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @email_input = FXTextField.new(fields_frame, 40, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Телефон
    FXLabel.new(fields_frame, "Телефон:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @phone_input = FXTextField.new(fields_frame, 20, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Telegram
    FXLabel.new(fields_frame, "Telegram:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @telegram_input = FXTextField.new(fields_frame, 30, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
  end
  
  def setup_buttons(parent)
    buttons_frame = FXHorizontalFrame.new(parent, 
      LAYOUT_FILL_X | PACK_UNIFORM_WIDTH,
      :padTop => 10)
    
    # Пустое пространство слева
    FXHorizontalFrame.new(buttons_frame, LAYOUT_FILL_X)
    
    # Кнопка OK
    ok_btn = FXButton.new(buttons_frame, "Сохранить", 
      nil, self, FXDialogBox::ID_ACCEPT,
      BUTTON_NORMAL | LAYOUT_RIGHT | FRAME_RAISED | FRAME_THICK,
      :padLeft => 20, :padRight => 5)
    
    # Кнопка Отмена
    cancel_btn = FXButton.new(buttons_frame, "Отмена", 
      nil, self, FXDialogBox::ID_CANCEL,
      BUTTON_NORMAL | LAYOUT_RIGHT | FRAME_RAISED | FRAME_THICK,
      :padLeft => 5, :padRight => 20)
    
    # Делаем кнопку OK по умолчанию
    ok_btn.setDefault
    
    # Обработчик для кнопки OK
    ok_btn.connect(SEL_COMMAND) do
      if validate_form
        save_student_data
        # Закрываем диалог с результатом OK
        handle(self, MKUINT(FXDialogBox::ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end
  
  def load_student_data
    return unless @student
    
    @last_name_input.text = @student.last_name || ""
    @first_name_input.text = @student.first_name || ""
    @patronymic_input.text = @student.patronymic || ""
    @git_input.text = @student.git || ""
    
    # Используем переменные экземпляра
    if @student.instance_variable_defined?(:@email)
      @email_input.text = @student.instance_variable_get(:@email) || ""
    end
    
    if @student.instance_variable_defined?(:@phone)
      @phone_input.text = @student.instance_variable_get(:@phone) || ""
    end
    
    if @student.instance_variable_defined?(:@telegram)
      @telegram_input.text = @student.instance_variable_get(:@telegram) || ""
    end
  end
  
  def save_student_data
    @student_data = {
      last_name: @last_name_input.text.strip,
      first_name: @first_name_input.text.strip,
      patronymic: @patronymic_input.text.strip.empty? ? nil : @patronymic_input.text.strip,
      git: @git_input.text.strip.empty? ? nil : @git_input.text.strip,
      email: @email_input.text.strip.empty? ? nil : @email_input.text.strip,
      phone: @phone_input.text.strip.empty? ? nil : @phone_input.text.strip,
      telegram: @telegram_input.text.strip.empty? ? nil : @telegram_input.text.strip
    }
  end
  
  def validate_form
    errors = []
    
    # Проверка обязательных полей
    if @last_name_input.text.strip.empty?
      errors << "Фамилия не может быть пустой"
    end
    
    if @first_name_input.text.strip.empty?
      errors << "Имя не может быть пустым"
    end
    
    unless errors.empty?
      error_message = "Обнаружены ошибки:\n\n" + errors.join("\n")
      FXMessageBox.error(self, MBOX_OK, "Ошибка валидации", error_message)
      return false
    end
    
    true
  end
end