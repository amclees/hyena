# frozen_string_literal: false

require 'json'
require 'date'

# Calendar keeps tracks of the events of each day and calls handlers as time progresses.
class Calendar
  attr_accessor :current_date
  attr_reader :event_hash

  def initialize(current_date, event_hash = {}, handlers = [])
    @current_date = current_date
    @event_hash = event_hash
    @handlers = []
    handlers.each do |handler|
      register_dependency_handler(handler)
    end
  end

  def advance_time(days)
    days.times do
      @current_date = (@current_date + 1)
      @handlers.each do |handler|
        handler.call(@current_date)
      end
    end
  end

  def get_events(date, id = 0)
    if @event_hash.key?(date)
      @event_hash[date].select { |event_data| event_data['id'] == id }.map { |event_data| event_data['text'] }
    else
      []
    end
  end

  def add_event(date, event, id = 0)
    event_data = {
      'id' => id,
      'text' => event
    }
    if @event_hash.key?(date)
      @event_hash[date].push(event_data)
    else
      @event_hash[date] = [event_data]
    end
  end

  def add_event_today(event, id = 0)
    add_event(@current_date, event, id)
  end

  def add_events(date, events, id = 0)
    events.each do |event|
      add_event(date, event, id)
    end
  end

  def register_dependency_handler(handler)
    @handlers.push(handler)
  end

  def to_json
    JSON.generate(
      current_date: @current_date.to_s,
      event_hash: @event_hash
    )
  end

  def self.from_json(json, handlers = [])
    parsed = JSON.parse(json)
    event_hash = parsed['event_hash']
    dated_event_hash = {}
    event_hash.each_pair do |date_string, event_array|
      dated_event_hash[Date.parse(date_string)] = event_array
    end
    Calendar.new Date.parse(parsed['current_date']), dated_event_hash, handlers
  end
end
