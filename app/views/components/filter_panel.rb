# app/views/components/filter_panel.rb
require 'fox16'
include Fox

class FilterPanel < FXGroupBox
  attr_reader :fio_input
  
  def initialize(parent)
    super(parent, "Фильтры", GROUPBOX_TITLE_LEFT | FRAME_GROOVE | LAYOUT_FILL_X)
    
    setup_filters
  end
  
  def reset
    @fio_input.text = ""
    
    [:git, :email, :phone, :telegram].each do |field|
      target = instance_variable_get("@#{field}_target")
      target.value = 2 if target
      
      input = instance_variable_get("@#{field}_input")
      input.text = ""
      input.disable
    end
  end
  
  def get_filters
    {
      fio: @fio_input.text.strip,
      git: {
        state: get_radio_state(:git),
        value: @git_input.text.strip
      },
      email: {
        state: get_radio_state(:email),
        value: @email_input.text.strip
      },
      phone: {
        state: get_radio_state(:phone),
        value: @phone_input.text.strip
      },
      telegram: {
        state: get_radio_state(:telegram),
        value: @telegram_input.text.strip
      }
    }
  end
  
  private
  
  def setup_filters
    main_frame = FXVerticalFrame.new(self, LAYOUT_FILL_X)
    
    setup_fio_filter(main_frame)
    setup_field_filter(main_frame, :git, "Гит")
    setup_field_filter(main_frame, :email, "Почта")
    setup_field_filter(main_frame, :phone, "Телефон")
    setup_field_filter(main_frame, :telegram, "Телеграмм")
  end
  
  def setup_fio_filter(parent)
    frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X)
    FXLabel.new(frame, "ФИО:", nil, LAYOUT_CENTER_Y)
    @fio_input = FXTextField.new(frame, 40, nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y)
    @fio_input.text = ""
  end
  
  def setup_field_filter(parent, field_name, label)
    frame = FXHorizontalFrame.new(parent, LAYOUT_FILL_X)
    
    FXLabel.new(frame, "#{label}:", nil, LAYOUT_CENTER_Y)
    
    data_target = FXDataTarget.new(2)
    instance_variable_set("@#{field_name}_target", data_target)
    
    radio_frame = FXHorizontalFrame.new(frame, LAYOUT_CENTER_Y)
    
    FXRadioButton.new(radio_frame, "Да", data_target, FXDataTarget::ID_OPTION + 0)
    FXRadioButton.new(radio_frame, "Нет", data_target, FXDataTarget::ID_OPTION + 1)
    FXRadioButton.new(radio_frame, "Не важно", data_target, FXDataTarget::ID_OPTION + 2)
    
    input = FXTextField.new(frame, 30, nil, 0, TEXTFIELD_NORMAL | LAYOUT_CENTER_Y)
    input.disable
    instance_variable_set("@#{field_name}_input", input)
    
    data_target.connect(SEL_COMMAND) do
      case data_target.value
      when 0
        input.enable
      when 1, 2
        input.disable
        input.text = ""
      end
    end
    
    input.disable
  end
  
  def get_radio_state(field_name)
    target = instance_variable_get("@#{field_name}_target")
    return "unknown" unless target
    
    case target.value
    when 0
      "yes"
    when 1
      "no"
    when 2
      "any"
    else
      "unknown"
    end
  end
  
  def git_input; @git_input; end
  def email_input; @email_input; end
  def phone_input; @phone_input; end
  def telegram_input; @telegram_input; end
end