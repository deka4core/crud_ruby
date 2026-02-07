require_relative '../models/student_list_json'
require_relative '../models/data_list_student_short'
require_relative '../core/observable'

class StudentListController
  attr_accessor :view
  attr_reader :current_page, :total_pages, :model, :data_list, :items_per_page
  
  def initialize(view = nil)
    @view = view
    
    current_dir = File.dirname(__FILE__)
    project_root = File.expand_path('../../', current_dir)
    data_path = File.join(project_root, 'data', 'students.json')
    
    @model = StudentsListJSON.new(data_path)
    
    @current_page = 1
    @items_per_page = 10
    @sort_column = 1
    @sort_direction = :asc
    @data_list = nil
    
    @all_students_cache = nil
    @all_students_sorted_cache = nil
    @cache_sort_column = nil
    @cache_sort_direction = nil
    
    reload_total_counts
    
    if @view
      @view.controller = self
    end
  end
  
  def refresh_data
    students_short = get_sorted_student_list_for_page
    
    if @data_list.nil?
      @data_list = DataListStudentShort.new(students_short)
      
      if @view
        @data_list.add_observer(@view)
      end
    else
      @data_list.update_data(students_short)
    end
    
    # Передаем смещение для правильной нумерации
    @data_list.page_offset = (@current_page - 1) * @items_per_page
    
    @data_list.notify if @data_list
    
    update_view_pagination
  end
  
  def get_sorted_student_list_for_page
    all_sorted = get_all_sorted_students
    
    start_index = (@current_page - 1) * @items_per_page
    end_index = start_index + @items_per_page - 1
    
    if start_index >= all_sorted.size
      return []
    end
    
    end_index = all_sorted.size - 1 if end_index >= all_sorted.size
    
    all_sorted[start_index..end_index] || []
  end
  
  def get_all_sorted_students
    if @all_students_cache.nil?
      @all_students_cache = get_all_students_from_model
    end
    
    if @all_students_sorted_cache.nil? || 
       @cache_sort_column != @sort_column || 
       @cache_sort_direction != @sort_direction
      
      @all_students_sorted_cache = if @sort_column == 1
        sort_by_fio(@all_students_cache)
      else
        @all_students_cache.dup
      end
      
      @cache_sort_column = @sort_column
      @cache_sort_direction = @sort_direction
    end
    
    @all_students_sorted_cache
  end
  
  def get_all_students_from_model
    total_count = @model.get_student_short_count
    
    all_students = @model.get_k_n_student_short_list(1, total_count)
    
    all_students
  end
  
  def sort_by_fio(students)
    sorted = students.sort_by do |student|
      if student.respond_to?(:last_name_initials)
        student.last_name_initials.to_s.strip.downcase
      else
        ""
      end
    end
    
    result = @sort_direction == :desc ? sorted.reverse : sorted
    
    result
  end
  
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
  
  def sort_by_column(column_index)
    return unless column_index == 1
    
    if @sort_column == column_index
      @sort_direction = (@sort_direction == :asc) ? :desc : :asc
    else
      @sort_column = column_index
      @sort_direction = :asc
    end
    
    @all_students_sorted_cache = nil
    
    @current_page = 1
    
    reload_total_counts
    refresh_data
  end
  
  def reload_file
    current_dir = File.dirname(__FILE__)
    project_root = File.expand_path('../../', current_dir)
    data_path = File.join(project_root, 'data', 'students.json')
    
    @model = StudentsListJSON.new(data_path)
    
    @all_students_cache = nil
    @all_students_sorted_cache = nil
    @cache_sort_column = nil
    @cache_sort_direction = nil
    
    @current_page = 1
    
    reload_total_counts
    
    refresh_data
  end
  
  private
  
  def reload_total_counts
    @total_items = @model.get_student_short_count
    @total_pages = calculate_total_pages
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