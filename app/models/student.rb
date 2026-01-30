require_relative 'base_student'

class Student < BaseStudent
  include Comparable
  attr_reader :first_name, :last_name, :patronymic

  def initialize(first_name:, last_name:, patronymic: nil, id: nil, git: nil, phone: nil, telegram: nil, email: nil)
    raise ArgumentError unless self.class.valid_git?(git)
    super(id: id, git: git)

    self.first_name = first_name
    self.last_name = last_name
    self.patronymic = patronymic
    
    self.contact_info = {telegram: telegram, email: email, phone: phone}
  end

  [:first_name, :last_name, :patronymic].each do |attr_name|
    define_method("#{attr_name}=") do |name|
      if attr_name == :patronymic && name.nil?
        @patronymic = nil
      else
        raise ArgumentError, "#{attr_name} cannot be nil" if name.nil?
        raise ArgumentError, "Invalid #{attr_name}" unless self.class.valid_name?(name)
        instance_variable_set("@#{attr_name}", name)
      end
    end
  end

  def last_name_initials
    initials = "#{last_name} #{first_name[0]}."
    initials += " #{patronymic[0]}." if patronymic
    initials
  end

  def contact_info=(contacts)
    contacts = {telegram: nil, email: nil, phone: nil}.merge(contacts)
    
    raise ArgumentError, "Invalid telegram" unless self.class.valid_telegram?(contacts[:telegram])
    @telegram = contacts[:telegram]

    raise ArgumentError, "Invalid email" unless self.class.valid_email?(contacts[:email])
    @email = contacts[:email]

    raise ArgumentError, "Invalid phone" unless self.class.valid_phone?(contacts[:phone])
    @phone = contacts[:phone]
  end

  def contact
    return "telegram - #{@telegram}" if @telegram
    return "email - #{@email}" if @email
    return "phone - #{@phone}" if @phone
    nil
  end

  def git=(new_git)
    raise ArgumentError, "Invalid git" unless self.class.valid_git?(new_git)
    @git = new_git
  end

  def self.valid_git?(git)
    return true if git.nil?
    github_pattern = /^https:\/\/github\.com\/[a-zA-Z0-9\-_]+(\/[a-zA-Z0-9\-_]+)*$/
    gitlab_pattern = /^https:\/\/gitlab\.com\/[a-zA-Z0-9\-_]+(\/[a-zA-Z0-9\-_]+)*$/
    
    git.match?(github_pattern) || git.match?(gitlab_pattern)
  end

  def self.valid_name?(name)
    name.match?(/^[A-ZА-Я][a-zа-я]*$/)
  end

  def self.valid_email?(email)
    return true if email.nil?
    email.match?(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)
  end

  def self.valid_phone?(phone)
    return true if phone.nil?
    phone.match?(/^(\+7|8)[\s\(\-]?\d{3}[\s\)\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}$/)
  end

  def self.valid_telegram?(telegram)
    return true if telegram.nil?
    telegram.match?(/^@[a-zA-Z0-9_]{5,}$/)
  end

  def <=>(other)
    return nil unless other.is_a?(BaseStudent)
    comparison_key <=> other.comparison_key
  end

  def ==(other)
    return false unless other.is_a?(BaseStudent)
    comparison_key == other.comparison_key
  end

  alias eql? ==

  def hash
    comparison_key.hash
  end

  private

  def fill_info_parts(info_parts)
    info_parts << "Фамилия: #{last_name}"
    info_parts << "Имя: #{first_name}"
    info_parts << "Отчество: #{patronymic}" if patronymic
    info_parts << "Телефон: #{@phone}" if @phone
    info_parts << "Email: #{@email}" if @email
    info_parts << "Telegram: #{@telegram}" if @telegram
    info_parts << "Git: #{git}" if git
  end

  def comparison_key
    [last_name, first_name, patronymic].map { |n| n || '' }
  end
end