# frozen_string_literal: false

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
  end

  def self.filename
    "calendar_#{@calendar_name}.json"
  end

  def self.load_calendar(name = @calendar_name)
    @calendar_name = name
    @calendar = JSONManager.exist?('world', filename) ? Calendar.from_json(JSONManager.read_json('world', filename)) : Calendar.new(Date.new)
  end

  def self.write_calendar(name = @calendar_name)
    @calendar_name = name
    JSONManager.write_json('world', filename + '.bak', JSONManager.delete_json('world', filename))
    JSONManager.write_json('world', filename, @calendar.to_json)
  end

  def calendar?(msg = nil)
    if calendar
      true
    else
      msg.respond('There is no open calendar.') if msg && msg&.respond
      false
    end
  end

  command(%i[date today], help_available: true, permission_level: 0) do |msg|
    return unless calendar?(msg)
    msg.respond("Today is #{@calendar.current_date.strftime(@date_format)}.")
    nil
  end

  command(%i[advance adv], help_available: false, permission_level: 90) do |msg, arg1|
    return unless calendar?(msg)
    days = arg1 ? arg1.to_i : nil
    if days
      @calendar.advance_time(days)
      msg.respond("Advanced time by #{days} days.")
      write_calendar
    else
      msg.respond('Please provide a valid number of days.')
    end
    nil
  end

  command(%i[calendar cal c], help_available: false, permission_level: 95) do |msg, arg1|
    msg.respond("Calendar IO not supported yet, you input:\n#{arg1}")
    nil
  end

  command(%i[event e], help_available: true, permission_level: 0) do |msg, action, *args|
    return unless calendar?(msg)
    msg.respond("Events not supported yet, you input:\n#{action}\n#{args.join(' ')}")
    nil
  end
end
