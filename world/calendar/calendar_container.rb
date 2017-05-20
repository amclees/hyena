# frozen_string_literal: false

require_relative '../../logger.rb'
require_relative '../../json_manager.rb'

# Calendar is the command container for calendar-related commands.
module CalendarContainer
  extend Discordrb::Commands::CommandContainer

  def self.init(bot, config)
    @bot = bot
    @config = config
  end
end
