# app/core/observer.rb
module Observer
  def on_observable_event(event_type, data = nil, observable = nil)
    # Метод должен быть переопределен в классах, включающих этот модуль
    raise NotImplementedError, "Метод on_observable_event должен быть реализован"
  end
end