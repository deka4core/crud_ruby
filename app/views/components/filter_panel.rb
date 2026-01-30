# app/views/components/filter_panel.rb
require 'fox16'
include Fox

class FilterPanel < FXGroupBox
  attr_reader :fio_filter
  
  def initialize(parent)
    super(parent, "Фильтры", GROUPBOX_TITLE_LEFT | FRAME_GROOVE | LAYOUT_FILL_X)
    
    create_ui
  end
  
  def get_filters
    {
      fio: @fio_filter.text.strip,
      git: get_filter_state(:git),
      contact: get_filter_state(:contact)
    }
  end
  
  def reset
    @fio_filter.text = ""
    
    [:git, :contact].each do |field|
      target = instance_variable_get("@#{field}_target")
      target.value = 2 if target
    end
  end
  
  private
  
  def create_ui
    main_frame = FXVerticalFrame.new(self, LAYOUT_FILL_X, padding: 10)
    
    # Фильтр по ФИО
    fio_frame = FXHorizontalFrame.new(main_frame, LAYOUT_FILL_X)
    FXLabel.new(fio_frame, "ФИО:", nil, LAYOUT_CENTER_Y)
    @fio_filter = FXTextField.new(fio_frame, 30, nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y | LAYOUT_FILL_X)
    
    # Фильтр по Git
    create_filter_field(main_frame, :git, "Наличие Git")
    
    # Фильтр по контакту
    create_filter_field(main_frame, :contact, "Наличие контакта")
    
    # Кнопки
    buttons_frame = FXHorizontalFrame.new(main_frame, LAYOUT_FILL_X)
    FXHorizontalFrame.new(buttons_frame, LAYOUT_FILL_X)
    
    reset_btn = FXButton.new(buttons_frame, "Сбросить")
    reset_btn.connect(SEL_COMMAND) { reset }
  end
  
  def create_filter_field(parent, field_name, label)
    frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X, padding: 5)
    
    FXLabel.new(frame, "#{label}:", nil, LAYOUT_CENTER_Y)
    
    target = FXDataTarget.new(2) # "Не важно" по умолчанию
    instance_variable_set("@#{field_name}_target", target)
    
    radio_frame = FXHorizontalFrame.new(frame, LAYOUT_CENTER_Y)
    
    FXRadioButton.new(radio_frame, "Да", target, FXDataTarget::ID_OPTION + 0)
    FXRadioButton.new(radio_frame, "Нет", target, FXDataTarget::ID_OPTION + 1)
    FXRadioButton.new(radio_frame, "Не важно", target, FXDataTarget::ID_OPTION + 2)
  end
  
  def get_filter_state(field_name)
    target = instance_variable_get("@#{field_name}_target")
    return {state: :any} unless target
    
    case target.value
    when 0
      {state: :present}
    when 1
      {state: :absent}
    else
      {state: :any}
    end
  end
end