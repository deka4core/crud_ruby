# app/models/student_list_json.rb
require 'json'

class StudentsListJSON
  attr_reader :students
  
  def initialize(file_path)
    @file_path = file_path
    @students = []
    load_data
  end
  
  def load_data
    puts "Загрузка данных из #{@file_path}..."
    
    unless File.exist?(@file_path)
      puts "Файл #{@file_path} не найден!"
      puts "Текущая директория: #{Dir.pwd}"
      return []
    end
    
    begin
      json_data = File.read(@file_path)
      puts "Размер файла: #{json_data.size} байт"
      
      data = JSON.parse(json_data, symbolize_names: true)
      puts "Загружено записей: #{data.size}"
      
      # Простая обработка данных
      @students = data.map.with_index do |student_data, i|
        # Создаем временный объект для хранения данных
        student = Object.new
        
        # Определяем методы для объекта
        student.define_singleton_method(:id) { student_data[:id] || i + 1 }
        
        # Формируем Фамилия И.О.
        initials = "#{student_data[:last_name]} #{student_data[:first_name][0]}."
        if student_data[:patronymic] && !student_data[:patronymic].empty?
          initials += " #{student_data[:patronymic][0]}."
        end
        
        student.define_singleton_method(:last_name_initials) { initials }
        student.define_singleton_method(:git) { student_data[:git] }
        
        # Определяем контакт
        contact = student_data[:phone] || student_data[:email] || student_data[:telegram]
        student.define_singleton_method(:contact) { contact }
        
        student
      end
      
      puts "Создано объектов: #{@students.size}"
      return @students
      
    rescue => e
      puts "Ошибка загрузки данных: #{e.message}"
      puts e.backtrace
      @students = []
    end
  end
  
  def get_k_n_student_short_list(k, n)
    start_index = (k - 1) * n
    end_index = start_index + n - 1
    
    # Проверяем границы
    start_index = 0 if start_index < 0
    end_index = @students.size - 1 if end_index >= @students.size
    
    page_students = @students[start_index..end_index] || []
    
    puts "get_k_n_student_short_list: k=#{k}, n=#{n}"
    puts "Диапазон: #{start_index}..#{end_index}"
    puts "Всего студентов: #{@students.size}"
    puts "Возвращается: #{page_students.size}"
    
    page_students
  end
  
  def get_student_short_count
    count = @students.size
    puts "get_student_short_count: #{count}"
    count
  end
end