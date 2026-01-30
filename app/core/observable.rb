# app/core/observable.rb
module Observable
  def add_observer(observer)
    @observers ||= []
    @observers << observer unless @observers.include?(observer)
  end
  
  def remove_observer(observer)
    @observers ||= []
    @observers.delete(observer)
  end
  
  def notify_observers(event_type, data = nil)
    @observers ||= []
    @observers.each do |observer|
      if observer.respond_to?(:on_observable_event)
        observer.on_observable_event(event_type, data, self)
      end
    end
  end
  
  def observers
    @observers ||= []
    @observers
  end
end