# app/controllers/student_list_controller.rb
require_relative '../models/student_list_json'
require_relative '../models/data_list_student_short'

class StudentListController
  attr_accessor :view
  attr_reader :current_page, :total_pages, :model
  
  def initialize(view = nil)
    @view = view
    puts "Контроллер инициализирован"
    
    # Абсолютный путь к файлу данных
    current_dir = File.dirname(__FILE__)
    project_root = File.expand_path('../../', current_dir)
    data_path = File.join(project_root, 'data', 'students.json')
    
    puts "Путь к данным: #{data_path}"
    puts "Файл существует? #{File.exist?(data_path)}"
    
    # Загружаем модель
    puts "Загрузка данных..."
    @model = StudentsListJSON.new(data_path)
    
    @current_page = 1
    @items_per_page = 10
    @total_pages = calculate_total_pages
    
    puts "Всего студентов: #{@model.get_student_short_count}"
    puts "Всего страниц: #{@total_pages}"
    
    # Обновляем View, если он передан
    if @view
      puts "Обновляем View..."
      refresh_data
    end
  end
  
  def refresh_data
    return unless @view
    
    puts "=== refresh_data вызван ==="
    puts "Текущая страница: #{@current_page}"
    
    begin
      # Получаем данные для текущей страницы
      students_short = @model.get_k_n_student_short_list(@current_page, @items_per_page)
      
      puts "Получено студентов на странице: #{students_short.size}"
      
      if students_short.empty?
        puts "Нет данных для отображения"
      end
      
      # Пересчитываем общее количество страниц
      @total_pages = calculate_total_pages
      puts "Всего страниц: #{@total_pages}"
      
      # Создаем DataList
      data_list = DataListStudentShort.new(students_short)
      
      # Обновляем View
      puts "Обновляем таблицу..."
      @view.set_table_data(data_list.get_data)
      puts "Обновляем пагинацию..."
      @view.update_pagination_info(@current_page, @total_pages)
      
      puts "=== refresh_data завершен ==="
    rescue => e
      puts "ОШИБКА в refresh_data: #{e.message}"
      puts e.backtrace
    end
  end
  
  # ... остальные методы остаются без изменений ...
  def next_page
    puts "next_page вызван"
    return false if @current_page >= @total_pages
    
    @current_page += 1
    refresh_data
    true
  end
  
  def prev_page
    puts "prev_page вызван"
    return false if @current_page <= 1
    
    @current_page -= 1
    refresh_data
    true
  end
  
  def go_to_page(page)
    page = page.to_i
    return false if page < 1 || page > @total_pages
    
    @current_page = page
    refresh_data
    true
  end
  
  def first_page
    puts "first_page вызван"
    return false if @current_page == 1
    
    @current_page = 1
    refresh_data
    true
  end
  
  def last_page
    puts "last_page вызван"
    return false if @current_page == @total_pages
    
    @current_page = @total_pages
    refresh_data
    true
  end
  
  def get_selected_student_ids(selected_rows)
    # Получаем студентов текущей страницы
    students_short = @model.get_k_n_student_short_list(@current_page, @items_per_page)
    
    # Преобразуем индексы строк в ID студентов
    selected_rows.map do |row_index|
      if row_index >= 0 && row_index < students_short.size
        students_short[row_index].id
      end
    end.compact
  end
  
  private
  
  def calculate_total_pages
    total_count = @model.get_student_short_count
    puts "Всего студентов в модели: #{total_count}"
    
    total_pages = (total_count.to_f / @items_per_page).ceil
    total_pages = 1 if total_pages == 0
    
    puts "Рассчитано страниц: #{total_pages}"
    total_pages
  end
end