# app/core/observable.rb
module Observable
  def observers
    @observers ||= []
  end
  
  def add_observer(observer)
    observers << observer unless observers.include?(observer)
  end
  
  def remove_observer(observer)
    observers.delete(observer)
  end
  
  def notify_observers(event, *args)
    observers.each do |observer|
      if observer.respond_to?(:on_observable_event)
        observer.on_observable_event(event, *args)
      end
    end
  end
end