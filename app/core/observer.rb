# app/core/observer.rb
module Observer
  def on_observable_event(event_type, data = nil)
    # Базовый метод, должен быть переопределен
  end
end