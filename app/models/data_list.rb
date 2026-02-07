require_relative 'data_table'

class DataList
  def initialize(data = [])
    @data = data.dup
    @selected_indices = []
  end
  
  def select(number)
    if number >= 0 && number < @data.length
      @selected_indices << number unless @selected_indices.include?(number)
    end
  end
  
  def get_selected
    result = []
    @selected_indices.sort.each do |index|
      item = @data[index]
      if item.respond_to?(:get_id)
        result << item.get_id
      elsif item.respond_to?(:id)
        result << item.id
      end
    end
    result
  end
  
  def get_names
    ["№ по порядку"] + column_names
  end
  
  def get_data(start_index=0)
    rows = []
    @data.each_with_index do |item, index|
      rows << [index + 1 + start_index] + row_values(item)
    end
    DataTable.new(rows)
  end
  
  def clear_selected
    @selected_indices.clear
  end
  
  def data=(new_data)
    @data = new_data.dup
    clear_selected
  end
  
  
  private
  
  def column_names
    raise NotImplementedError, "Метод 'column_names' должен быть реализован в наследнике"
  end
  
  def row_values(item)
    raise NotImplementedError, "Метод 'row_values' должен быть реализован в наследнике"
  end
  
  protected
  
  def items
    @data
  end
  
  def selected_indices
    @selected_indices
  end
end