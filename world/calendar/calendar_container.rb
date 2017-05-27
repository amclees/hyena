# frozen_string_literal: false

require 'date'
require_relative '../../logger.rb'
require_relative '../../json_manager.rb'
require_relative './calendar.rb'

# Calendar is the command container for calendar-related commands.
module CalendarContainer
  extend Discordrb::Commands::CommandContainer
  @date_format = '%Y-%m-%d'

  def self.init(bot, config)
    @bot = bot
    @config = config

    load_calendar('main') if JSONManager.exist?('world', 'calendar_main.rb')
  end

  def self.filename
    "calendar_#{@calendar_name}.json"
  end

  def self.date_string
    @calendar.current_date.strftime(@date_format)
  end

  def self.load_calendar(name = @calendar_name)
    @calendar_name = name
    @calendar = JSONManager.exist?('world', filename) ? Calendar.from_json(JSONManager.read_json('world', filename)) : Calendar.new(Date.new)
  end

  def self.write_calendar(name = @calendar_name)
    return unless @calendar
    @calendar_name = name
    old_json = JSONManager.delete_json('world', filename)
    JSONManager.write_json('world', filename + '.bak', old_json) if old_json
    JSONManager.write_json('world', filename, @calendar.to_json)
  end

  def self.calendar?(msg = nil)
    if @calendar
      true
    else
      msg&.respond('There is no open calendar.') if msg
      false
    end
  end

  command(%i[date today], help_available: true, permission_level: 0) do |msg|
    return unless calendar?(msg)
    msg.respond("Today is #{date_string}.")
    nil
  end

  command(%i[advance adv], help_available: false, permission_level: 90) do |msg, arg1|
    return unless calendar?(msg)
    days = arg1 ? arg1.to_i : nil
    if days && days.positive?
      @calendar.advance_time(days)
      msg.respond("Advanced time by #{days} days.")
      write_calendar
    else
      msg.respond('Please provide a valid number of days.')
    end
    nil
  end

  command(%i[calendar cal c], help_available: false, permission_level: 95) do |msg, arg1, *args|
    date_str = args && !args.length.zero? ? args.join('-') : ''

    begin
      date = Date.parse(date_str)
    rescue ArgumentError
      date = nil
    end

    if JSONManager.valid_filename?(arg1)
      load_calendar(arg1)
      @calendar.current_date = date if date
      msg.respond(date ? "Created new calendar #{arg1} starting at #{date_string}" : "Opened calendar #{arg1}")
      write_calendar
    else
      msg.respond("Invalid calendar #{date_str}")
    end
    nil
  end

  command(%i[event e], help_available: true, permission_level: 0) do |msg, action, *args|
    return unless calendar?(msg)
    msg.respond("Events not supported yet, you input:\n#{action}\n#{args.join(' ')}")
    nil
  end
end
