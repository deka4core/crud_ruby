# app/views/dialogs/student_dialog.rb
require 'fox16'
include Fox

class StudentDialog < FXDialogBox
  # Константы для кнопок
  ID_ACCEPT = FXDialogBox::ID_ACCEPT
  ID_CANCEL = FXDialogBox::ID_CANCEL
  
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
    result
  end
  
  def result
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
    @last_name_input.backColor = FXRGB(255, 255, 240)
    
    # Имя (обязательное)
    FXLabel.new(fields_frame, "Имя:*", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @first_name_input = FXTextField.new(fields_frame, 30, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    @first_name_input.backColor = FXRGB(255, 255, 240)
    
    # Отчество (необязательное)
    FXLabel.new(fields_frame, "Отчество:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @patronymic_input = FXTextField.new(fields_frame, 30, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Пустая строка для разделения
    FXLabel.new(fields_frame, "")
    FXLabel.new(fields_frame, "")
    
    # Git
    FXLabel.new(fields_frame, "Git URL:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @git_input = FXTextField.new(fields_frame, 40, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Подсказка для Git
    FXLabel.new(fields_frame, "")
    FXLabel.new(fields_frame, "Пример: https://github.com/username или https://gitlab.com/username",
      nil, JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    
    # Email
    FXLabel.new(fields_frame, "Email:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @email_input = FXTextField.new(fields_frame, 40, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Подсказка для Email
    FXLabel.new(fields_frame, "")
    FXLabel.new(fields_frame, "Пример: user@example.com",
      nil, JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    
    # Телефон
    FXLabel.new(fields_frame, "Телефон:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @phone_input = FXTextField.new(fields_frame, 20, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Подсказка для телефона
    FXLabel.new(fields_frame, "")
    FXLabel.new(fields_frame, "Формат: +79123456789 или 89123456789",
      nil, JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    
    # Telegram
    FXLabel.new(fields_frame, "Telegram:", nil, 
      JUSTIFY_LEFT | LAYOUT_CENTER_Y)
    @telegram_input = FXTextField.new(fields_frame, 30, 
      nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Подсказка для Telegram
    FXLabel.new(fields_frame, "")
    FXLabel.new(fields_frame, "Формат: @username",
      nil, JUSTIFY_LEFT | LAYOUT_CENTER_Y)
  end
  
  def setup_buttons(parent)
    buttons_frame = FXHorizontalFrame.new(parent, 
      LAYOUT_FILL_X | PACK_UNIFORM_WIDTH,
      :padTop => 10)
    
    # Пустое пространство слева
    FXHorizontalFrame.new(buttons_frame, LAYOUT_FILL_X)
    
    # Кнопка OK
    ok_btn = FXButton.new(buttons_frame, "Сохранить", 
      nil, self, ID_ACCEPT,
      BUTTON_NORMAL | LAYOUT_RIGHT | FRAME_RAISED | FRAME_THICK,
      :padLeft => 20, :padRight => 5)
    ok_btn.textColor = FXRGB(0, 100, 0)
    
    # Кнопка Отмена
    cancel_btn = FXButton.new(buttons_frame, "Отмена", 
      nil, self, ID_CANCEL,
      BUTTON_NORMAL | LAYOUT_RIGHT | FRAME_RAISED | FRAME_THICK,
      :padLeft => 5, :padRight => 20)
    cancel_btn.textColor = FXRGB(100, 0, 0)
    
    # Делаем кнопку OK по умолчанию
    ok_btn.setDefault
    
    # Обработчик для кнопки OK
    ok_btn.connect(SEL_COMMAND) do
      if validate_form
        save_student_data
        # Закрываем диалог с результатом OK
        handle(self, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end
  
  def load_student_data
    return unless @student
    
    @last_name_input.text = @student.last_name || ""
    @first_name_input.text = @student.first_name || ""
    @patronymic_input.text = @student.patronymic || ""
    @git_input.text = @student.git || ""
    
    # Используем геттеры или переменные экземпляра
    if @student.respond_to?(:email) && @student.email
      @email_input.text = @student.email
    elsif @student.instance_variable_defined?(:@email)
      @email_input.text = @student.instance_variable_get(:@email) || ""
    end
    
    if @student.respond_to?(:phone) && @student.phone
      @phone_input.text = @student.phone
    elsif @student.instance_variable_defined?(:@phone)
      @phone_input.text = @student.instance_variable_get(:@phone) || ""
    end
    
    if @student.respond_to?(:telegram) && @student.telegram
      @telegram_input.text = @student.telegram
    elsif @student.instance_variable_defined?(:@telegram)
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
    
    # Валидация email если указан
    email = @email_input.text.strip
    unless email.empty?
      unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
        errors << "Неверный формат email"
      end
    end
    
    # Валидация телефона если указан
    phone = @phone_input.text.strip
    unless phone.empty?
      unless phone.match?(/^(\+7|8)[\s\-]?\(?\d{3}\)?[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}$/)
        errors << "Неверный формат телефона. Используйте: +79123456789 или 89123456789"
      end
    end
    
    # Валидация telegram если указан
    telegram = @telegram_input.text.strip
    unless telegram.empty?
      unless telegram.match?(/^@[a-zA-Z0-9_]{5,}$/)
        errors << "Неверный формат Telegram. Используйте: @username (минимум 5 символов после @)"
      end
    end
    
    # Валидация Git если указан
    git = @git_input.text.strip
    unless git.empty?
      unless git.match?(/^https:\/\/(github|gitlab)\.com\/[a-zA-Z0-9\-_]+\/?/)
        errors << "Неверный формат Git URL. Используйте: https://github.com/username или https://gitlab.com/username"
      end
    end
    
    unless errors.empty?
      error_message = "Обнаружены ошибки:\n\n" + errors.join("\n")
      FXMessageBox.error(self, MBOX_OK, "Ошибка валидации", error_message)
      return false
    end
    
    true
  end
end