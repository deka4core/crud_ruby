# app/views/components/pagination_panel.rb
require 'fox16'
include Fox
require_relative '../../core/observable'

class PaginationPanel < FXHorizontalFrame
  include Observable
  
  attr_reader :current_page, :total_pages, :items_per_page
  
  def initialize(parent, controller = nil)
    super(parent, LAYOUT_FILL_X | PACK_UNIFORM_WIDTH)
    
    @controller = controller
    @current_page = 1
    @total_pages = 1
    @items_per_page = 20
    
    setup_pagination
  end

  def current_page=(page)
    @current_page = page
    update_display
  end
  
  def update_info(total_items)
    @total_pages = [1, (total_items.to_f / @items_per_page).ceil].max
    @current_page = 1 if @current_page > @total_pages
    
    update_display
  end
  
  private
  
  def setup_pagination
    # Кнопка "Назад"
    @prev_btn = FXButton.new(self, "← Назад")
    @prev_btn.disable
    
    # Информация о странице
    @page_label = FXLabel.new(self, "Страница 1 из 1", nil, LAYOUT_CENTER_Y)
    
    # Кнопка "Вперед"
    @next_btn = FXButton.new(self, "Вперед →")
    @next_btn.disable
    
    # Обработчики
    @prev_btn.connect(SEL_COMMAND) { prev_page }
    @next_btn.connect(SEL_COMMAND) { next_page }
  end
  
  def update_display
    @page_label.text = "Страница #{@current_page} из #{@total_pages}"
    
    if @current_page > 1
      @prev_btn.enable
    else
      @prev_btn.disable
    end
    
    if @current_page < @total_pages
      @next_btn.enable
    else
      @next_btn.disable
    end
  end
  
  def next_page
    change_page(@current_page + 1) if @current_page < @total_pages
  end
  
  def prev_page
    change_page(@current_page - 1) if @current_page > 1
  end
  
  def change_page(new_page)
    @current_page = new_page
    update_display
    notify_observers(:page_changed, @current_page)
  end
end