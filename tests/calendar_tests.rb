# frozen_string_literal: false

require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'date'
require_relative '../world/calendar/calendar.rb'

# Tests calendar including handlers, events, and JSON serialization
class CalendarTest < Test::Unit::TestCase
  def test_time
    calendar = Calendar.new(Date.new(1002, 2, 3))
    calendar.advance_time(5)
    assert(calendar.current_date === Date.new(1002, 2, 8))
    calendar.advance_time(365 * 1000)
    assert(calendar.current_date === Date.new(2001, 6, 16))
  end

  def test_handlers
    counter = 0
    handler1 = lambda do |current_date|
      counter += current_date.day
    end
    handler2 = lambda do |_current_date|
      counter -= 1
    end
    handlers = [handler1, handler2]
    calendar = Calendar.new(Date.new(4016, 6, 12), {}, handlers)
    calendar.advance_time(3)
    assert_equal(39, counter)
  end

  def test_events
    calendar = Calendar.new(Date.new(4016, 5, 11), {}, [])
    calendar.add_event_today('Defeated werewolf')
    calendar.advance_time(1)
    calendar.add_event(Date.new(4016, 2, 5), 'Face of Gruumsh completed')
    events = ['Left Redfoot', 'Reached beach']
    calendar.add_events(calendar.current_date, events)
    assert_equal(['Defeated werewolf'], calendar.get_events(Date.new(4016, 5, 11)))
    assert_equal(['Face of Gruumsh completed'], calendar.get_events(Date.new(4016, 2, 5)))
    assert_equal(['Left Redfoot', 'Reached beach'], calendar.get_events_today)
    assert_equal([], calendar.get_events(Date.new(4016, 6, 12)))
  end

  def test_json
    calendar = Calendar.new(Date.new(4016, 5, 11), {}, [])
    calendar.add_event_today('Defeated werewolf')
    calendar.advance_time(1)
    calendar.add_event(Date.new(4016, 2, 5), 'Face of Gruumsh completed')
    events = ['Left Redfoot', 'Reached beach']
    calendar.add_events(calendar.current_date, events)
    calendar_json = calendar.to_json
    calendar_from_json = Calendar.from_json(calendar_json)
    assert_equal(['Defeated werewolf'], calendar_from_json.get_events(Date.new(4016, 5, 11)))
    assert_equal(['Face of Gruumsh completed'], calendar_from_json.get_events(Date.new(4016, 2, 5)))
    assert_equal(['Left Redfoot', 'Reached beach'], calendar_from_json.get_events(Date.new(4016, 5, 12)))
    assert_equal([], calendar.get_events(Date.new(4016, 6, 12)))
  end
end
