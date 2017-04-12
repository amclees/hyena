require 'json'

class Calendar
  def initialize(current_date, event_hash, handlers)
    @current_date = current_date
    @event_hash = event_hash
    @handlers = []
    handlers.each do |handler|
      register_dependency_handler(handler)
    end
  end

  def advance_time(days)
    for i in 0...days do
      current_date = (current_date += 1)
      @handlers.each do |handler|
        handler.call(current_date)
      end
    end
  end

  def get_events(date)

  end

  def add_event(date, event)

  end

  def add_events(date, *events)
    
  end

  def register_dependency_handler(&handler)
    @handlers.push(handler)
  end

  def to_json
    JSON.generate({
      :current_date => current_date.to_s,
      :event_hash => event_hash
    })
  end

  def self.from_json(json)
    parsed = JSON.parse(json)
    Calendar.new Date.parse(parsed["current_date"]), parsed["event_hash"], []
  end
end
