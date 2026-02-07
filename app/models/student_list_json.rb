require 'json'

class StudentsListJSON
  attr_reader :students
  
  def initialize(file_path)
    @file_path = file_path
    @students = []
    load_data
  end
  
  def load_data
    unless File.exist?(@file_path)
      return []
    end
    
    begin
      json_data = File.read(@file_path)
      data = JSON.parse(json_data, symbolize_names: true)
      
      @students = data.map.with_index do |student_data, i|
        student = Object.new
        
        student.define_singleton_method(:id) { student_data[:id] || i + 1 }
        
        initials = "#{student_data[:last_name]} #{student_data[:first_name][0]}."
        if student_data[:patronymic] && !student_data[:patronymic].empty?
          initials += " #{student_data[:patronymic][0]}."
        end
        
        student.define_singleton_method(:last_name_initials) { initials }
        student.define_singleton_method(:git) { student_data[:git] }
        
        contact = student_data[:phone] || student_data[:email] || student_data[:telegram]
        student.define_singleton_method(:contact) { contact }
        
        student
      end
      
      return @students
      
    rescue => e
      @students = []
    end
  end
  
  def get_k_n_student_short_list(k, n)
    if n <= 0 || n >= @students.size
      return @students.dup
    end
    
    start_index = (k - 1) * n
    end_index = start_index + n - 1
    
    if start_index >= @students.size
      return []
    end
    
    end_index = @students.size - 1 if end_index >= @students.size
    
    result = @students[start_index..end_index] || []
    
    result
  end

  def get_student_short_count
    @students.size
  end
end