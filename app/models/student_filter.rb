# app/models/student_filter.rb
class StudentFilter
  def apply_filters(students, filters)
    return students unless filters && !filters.empty?
    
    filtered = students.select do |student|
      matches_all_filters?(student, filters)
    end
    
    filtered
  end
  
  private
  
  def matches_all_filters?(student, filters)
    # Фильтр по ФИО
    if filters[:fio] && !filters[:fio].empty?
      fio_text = filters[:fio].downcase
      student_fio = student.last_name_initials.to_s.downcase
      return false unless student_fio.include?(fio_text)
    end
    
    # Фильтр по Git
    if filters[:git]
      return false unless matches_git_filter?(student, filters[:git])
    end
    
    # Фильтр по контакту
    if filters[:contact]
      return false unless matches_contact_filter?(student, filters[:contact])
    end
    
    true
  end
  
  def matches_git_filter?(student, git_filter)
    has_git = !student.git.nil? && !student.git.empty?
    
    case git_filter[:state]
    when :present
      return false unless has_git
      
      # Если есть текст для поиска в Git
      if git_filter[:text] && !git_filter[:text].empty?
        git_text = git_filter[:text].downcase
        student_git = student.git.to_s.downcase
        return false unless student_git.include?(git_text)
      end
      
    when :absent
      return false if has_git
      
    when :any
      # Не важно, пропускаем
    end
    
    true
  end
  
  def matches_contact_filter?(student, contact_filter)
    has_contact = !student.contact.nil? && !student.contact.empty?
    
    case contact_filter[:state]
    when :present
      return false unless has_contact
    when :absent
      return false if has_contact
    when :any
      # Не важно, пропускаем
    end
    
    true
  end
end