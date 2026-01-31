# app/controllers/student_list_controller.rb
require_relative '../models/student_list_json'
require_relative '../models/data_list_student_short'
require_relative '../core/observable'

class StudentListController
  include Observable
  attr_accessor :view
  attr_reader :current_page, :total_pages, :model, :data_list, :items_per_page
  
  def initialize(view = nil)
    @view = view
    puts "StudentListController инициализирован"
    
    # Загружаем модель
    current_dir = File.dirname(__FILE__)
    project_root = File.expand_path('../../', current_dir)
    data_path = File.join(project_root, 'data', 'students.json')
    
    puts "Загрузка данных из: #{data_path}"
    @model = StudentsListJSON.new(data_path)
    
    # Инициализация состояния
    @current_page = 1
    @items_per_page = 10
    @sort_column = 1
    @sort_direction = :asc
    @data_list = nil
    
    # Кэш для всех студентов
    @all_students_cache = nil
    @all_students_sorted_cache = nil
    @cache_sort_column = nil
    @cache_sort_direction = nil
    
    # Рассчитываем общее количество
    reload_total_counts
    
    puts "Всего студентов: #{@total_items}"
    puts "Всего страниц: #{@total_pages}"
    
    if @view
      @view.controller = self
    end
  end
  
  def refresh_data
    puts "=== controller.refresh_data вызван ==="
    puts "Страница: #{@current_page}, всего: #{@total_pages}"
    
    # Получаем отсортированные данные для текущей страницы
    students_short = get_sorted_student_list_for_page
    
    puts "Получено студентов для страницы: #{students_short.size}"
    
    # Создаем или обновляем DataListStudentShort
    if @data_list.nil?
      puts "Создаем новый DataListStudentShort"
      @data_list = DataListStudentShort.new(students_short)
      
      if @view
        puts "Добавляем View как наблюдателя"
        @data_list.add_observer(@view)
      end
    else
      puts "Обновляем существующий DataListStudentShort (ID: #{@data_list.object_id})"
      @data_list.update_data(students_short)
    end
    
    # Вызываем notify у DataList
    @data_list.notify if @data_list
    
    # Обновляем информацию о пагинации
    update_view_pagination
    
    puts "=== controller.refresh_data завершен ==="
  end
  
  # Получить отсортированные данные для ТЕКУЩЕЙ страницы
  def get_sorted_student_list_for_page
    # 1. Получить ВСЕ отсортированные данные
    all_sorted = get_all_sorted_students
    
    # 2. Рассчитать индексы для текущей страницы
    start_index = (@current_page - 1) * @items_per_page
    end_index = start_index + @items_per_page - 1
    
    # 3. Проверить границы
    if start_index >= all_sorted.size
      puts "Начальный индекс #{start_index} за пределами данных, возвращаем пустой список"
      return []
    end
    
    # 4. Корректируем конечный индекс
    end_index = all_sorted.size - 1 if end_index >= all_sorted.size
    
    puts "Диапазон для страницы #{@current_page}: #{start_index}..#{end_index}"
    
    # 5. Возвращаем срез
    all_sorted[start_index..end_index] || []
  end
  
  # Получить ВСЕ данные, отсортированные
  def get_all_sorted_students
    # 1. Получить все данные из модели (кэшируем)
    if @all_students_cache.nil?
      puts "Загрузка всех студентов из модели..."
      @all_students_cache = get_all_students_from_model
      puts "Загружено студентов: #{@all_students_cache.size}"
    end
    
    # 2. Проверяем, нужно ли пересортировывать
    if @all_students_sorted_cache.nil? || 
       @cache_sort_column != @sort_column || 
       @cache_sort_direction != @sort_direction
      
      puts "Пересортировка данных..."
      puts "Сортировка по столбцу: #{@sort_column}, направление: #{@sort_direction}"
      
      # 3. Сортируем ВСЕ данные
      @all_students_sorted_cache = if @sort_column == 1
        sort_by_fio(@all_students_cache)
      else
        @all_students_cache.dup
      end
      
      # 4. Сохраняем параметры сортировки для кэша
      @cache_sort_column = @sort_column
      @cache_sort_direction = @sort_direction
    else
      puts "Используем кэшированные отсортированные данные"
    end
    
    @all_students_sorted_cache
  end
  
  # Получить ВСЕХ студентов из модели
  def get_all_students_from_model
    total_count = @model.get_student_short_count
    puts "Всего студентов в модели: #{total_count}"
    
    # Используем большой лимит чтобы получить всех
    all_students = @model.get_k_n_student_short_list(1, total_count)
    
    # Проверяем что получили всех
    puts "Получено студентов: #{all_students.size}"
    
    if all_students.size != total_count
      puts "ВНИМАНИЕ: Получено #{all_students.size} студентов, но ожидалось #{total_count}"
    end
    
    all_students
  end
  
  # Сортировка по ФИО
  def sort_by_fio(students)
    puts "Сортировка #{students.size} записей по ФИО"
    
    # Выводим первые 5 записей для отладки
    puts "Первые 5 записей до сортировки:"
    students.first(5).each_with_index do |s, i|
      puts "  #{i}: #{s.last_name_initials}" if s.respond_to?(:last_name_initials)
    end
    
    sorted = students.sort_by do |student|
      if student.respond_to?(:last_name_initials)
        student.last_name_initials.to_s.strip.downcase
      else
        ""
      end
    end
    
    puts "Первые 5 записей после сортировки (направление: #{@sort_direction}):"
    result = @sort_direction == :desc ? sorted.reverse : sorted
    result.first(5).each_with_index do |s, i|
      puts "  #{i}: #{s.last_name_initials}" if s.respond_to?(:last_name_initials)
    end
    
    result
  end
  
  # Методы пагинации
  def next_page
    return false if @current_page >= @total_pages
    
    @current_page += 1
    refresh_data
    true
  end
  
  def prev_page
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
    return false if @current_page == 1
    
    @current_page = 1
    refresh_data
    true
  end
  
  def last_page
    return false if @current_page == @total_pages
    
    @current_page = @total_pages
    refresh_data
    true
  end
  
  # Сортировка
  def sort_by_column(column_index)
    return unless column_index == 1
    
    puts "Сортировка по Фамилия И.О."
    
    if @sort_column == column_index
      @sort_direction = (@sort_direction == :asc) ? :desc : :asc
    else
      @sort_column = column_index
      @sort_direction = :asc
    end
    
    puts "Направление: #{@sort_direction}"
    
    # Сбрасываем кэш отсортированных данных
    @all_students_sorted_cache = nil
    
    # Сбрасываем на первую страницу
    @current_page = 1
    
    # Пересчитываем общее количество
    reload_total_counts
    refresh_data
  end
  
  # Перезагрузка файла
  def reload_file
    puts "Перезагрузка файла данных..."
    
    current_dir = File.dirname(__FILE__)
    project_root = File.expand_path('../../', current_dir)
    data_path = File.join(project_root, 'data', 'students.json')
    
    @model = StudentsListJSON.new(data_path)
    
    # Сбрасываем все кэши
    @all_students_cache = nil
    @all_students_sorted_cache = nil
    @cache_sort_column = nil
    @cache_sort_direction = nil
    
    @current_page = 1
    
    # Пересчитываем
    reload_total_counts
    
    refresh_data
  end
  
  private
  
  def reload_total_counts
    # Получаем общее количество студентов
    @total_items = @model.get_student_short_count
    @total_pages = calculate_total_pages
    
    puts "Пересчет: всего студентов #{@total_items}, страниц #{@total_pages}"
  end
  
  def calculate_total_pages
    return 1 if @total_items <= 0
    (@total_items.to_f / @items_per_page).ceil
  end
  
  def update_view_pagination
    return unless @view && @view.respond_to?(:on_observable_event)
    
    @view.on_observable_event(:pagination_changed, {
      current_page: @current_page,
      total_pages: @total_pages
    })
  end
end