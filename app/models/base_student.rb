class BaseStudent
  attr_reader :id, :git

  def initialize(id: nil, git: nil)
    @id = id
    @git = git
  end

  def to_s
    info_parts = []
    info_parts << "ID: #{@id}" if @id
    fill_info_parts(info_parts)
    info_parts.join(", ")
  end

  def short_info
    info_parts = []
    info_parts << @id.to_s if @id
    info_parts << last_name_initials
    info_parts << contact if has_contact?
    info_parts << git if has_git?
    info_parts.join(", ")
  end

  def has_git?
    !git.nil?
  end

  def has_contact?
    !contact.nil?
  end

  protected

  def fill_info_parts(info_parts)
    raise NotImplementedError, "Subclasses must implement #fill_info_parts"
  end

  def comparison_key
    raise NotImplementedError, "Subclasses must implement #comparison_key"
  end

  def contact
    raise NotImplementedError, "Subclasses must implement #contact"
  end

  def last_name_initials
    raise NotImplementedError, "Subclasses must implement #last_name_initials"
  end
end