class DataTable
  def initialize(data)
    @data = data
  end
  
  def get_element(row, col)
    @data[row][col] if valid_indices?(row, col)
  end
  
  def rows_count
    @data.size
  end
  
  def columns_count
    return 0 if @data.empty?
    @data[0].size
  end
  
  private
  
  def valid_indices?(row, col)
    row >= 0 && row < rows_count && col >= 0 && col < columns_count
  end
end