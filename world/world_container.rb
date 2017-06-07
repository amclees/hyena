# frozen_string_literal: false

require_relative '../logger.rb'
require_relative '../json_manager.rb'

require_relative './calendar/calendar_container.rb'

# World is the command container for interconnected world commands and runs the other world containers.
module WorldContainer
  extend Discordrb::Commands::CommandContainer

  def self.init(bot, config)
    @bot = bot
    @config = config

    CalendarContainer.init(@bot, @config)

    @bot.include! WorldContainer
  end
end
