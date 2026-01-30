# app/models/student_filter.rb
class StudentFilter
  def apply_filters(students, filters)
    return students unless filters && !filters.empty?
    
    students.select do |student|
      matches_filters?(student, filters)
    end
  end
  
  private
  
  def matches_filters?(student, filters)
    # Фильтр по ФИО
    if filters[:fio] && !filters[:fio].empty?
      full_name = student.last_name_initials.downcase
      return false unless full_name.include?(filters[:fio].downcase)
    end
    
    # Фильтр по Git
    if filters[:git] && filters[:git][:state] != :any
      has_git = !student.git.nil? && !student.git.empty?
      
      case filters[:git][:state]
      when :present
        return false unless has_git
      when :absent
        return false if has_git
      end
    end
    
    # Фильтр по контакту
    if filters[:contact] && filters[:contact][:state] != :any
      has_contact = !student.contact.nil? && !student.contact.empty?
      
      case filters[:contact][:state]
      when :present
        return false unless has_contact
      when :absent
        return false if has_contact
      end
    end
    
    true
  end
end