require_relative 'base_student'
require_relative 'student'

class StudentShort < BaseStudent
  attr_reader :last_name_initials, :contact

  def initialize(id:, last_name_initials:, contact: nil, git: nil)
    super(id: id, git: git)
    @last_name_initials = last_name_initials
    @contact = contact
  end

  def self.from_student(student)
    new(
      id: student.id,
      last_name_initials: student.last_name_initials,
      contact: student.contact,
      git: student.git
    )
  end

  private

  def fill_info_parts(info_parts)
    info_parts << "Фамилия и инициалы: #{@last_name_initials}" if @last_name_inititals
    info_parts << "Контакт: #{@contact}" if @contact
    info_parts << "Git: #{@git}" if @git
  end

  def comparison_key
    [@last_name_initials || '']
  end
end