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

    load_calendar('main') if JSONManager.exist?('world', 'calendar_main.json')

    @bot.include! CalendarContainer
  end

  def self.filename
    "calendar_#{@calendar_name}.json"
  end

  def self.date_string(date = @calendar.current_date)
    date.strftime(@date_format)
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

  def self.valid_date(date_str)
    if date_str
      begin
        date = Date.parse(date_str)
      rescue ArgumentError
        date = nil
      end
    else
      date = nil
    end
    date
  end

  def self.validate(args, msg = nil)
    args.each do |arg|
      unless arg
        msg&.respond('Please try again with valid input as shown by the help command.') if msg
        return false
      end
    end
    true
  end

  command(%i[date today], description: 'Displays the current in-game date.', permission_level: 0) do |msg|
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
    date_str = args && args.length.positive? ? args.join('-') : ''

    date = valid_date(date_str)

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

  command(%i[event e], description: 'Allows editing events. Try `event help` for more details.', permission_level: 0) do |msg, action, *args|
    return unless calendar?(msg)
    date = args && args.length.positive? ? valid_date(args.shift) : nil
    # Recalculation of args.length.positive? needed because the above args.shift could bring it to 0.
    # args[0] check ensures there is text for the event.
    text = args && args.length.positive? && args[0].strip.length.positive? ? args.join(' ') : nil
    if %w[help h].include?(action)
      msg.respond(
        <<~HELP_TEXT
          The `event` (or `e`) commands allow you to set events on particular dates to keep track of what has happened in-game.
          Please be sure to specify a valid date seperated by dashes: YYYY-MM-DD for example, will work.
            `add <date> <event text>`  (`a`) - Adds an event to the specified date with the specified text.
            `show <date>` (`s`) - Shows all events for a particular date.
            `list` (`ls`) - Lists recent dates along with the number of events that occured on each date.
        HELP_TEXT
      )
    elsif %w[add a].include?(action)
      return unless validate([date, text], msg)
      @calendar.add_event(date, text)
      msg.respond('Successfully added event.')
      write_calendar
    elsif %w[show view s v].include?(action)
      return unless validate([date], msg)
      events = @calendar.get_events(date)
      if events.empty?
        msg.respond("There were no events on #{date_string(date)}.")
      else
        msg.respond("The events on #{date_string(date)} were:\n```#{events.join("\n")}```")
      end
    elsif %w[list ls].include?(action)
      sorted_keys = @calendar.event_hash.keys.sort
      date_texts = sorted_keys.map do |date_key|
        "#{date_string(date_key)} - Events: #{@calendar.get_events(date_key).length}"
      end
      date_text = ''
      date_text << date_texts.pop << "\n" while date_text.length < 2000 && !date_texts.empty?
      msg.respond(date_text)
    else
      msg.respond('Invalid action, try `event help` to see how to use calendar events.')
    end
    nil
  end
end
