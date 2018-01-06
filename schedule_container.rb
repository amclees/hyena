# frozen_string_literal: false

require_relative './logger.rb'
require 'date'

# ScheduleContainer is the container for commands relating to session scheduling.
module ScheduleContainer
  extend Discordrb::Commands::CommandContainer

  def self.init(bot)
    @bot = bot

    @bot.message do |msg|
      text = msg.content.downcase
      if @suggested_date
        if text.include? 'let\'s just not play'
          @suggested_date = nil
          msg.respond(':disappointed:')
        elsif text.include? 'ok'
          @works_for_count += 1
          @response_count += 1
          msg.respond(":smiley: Looks like #{@works_for_count}/#{@response_count} will be able to make it so far")
        elsif text.include?('i can\'t') || text.include?('no')
          @response_count += 1
          msg.respond(":frowning2: Looks like #{@works_for_count}/#{@response_count} will be able to make it so far")
        elsif msg.content =~ /what about in (\d) hour/i
          hours_away = msg.content.scan(/what about in (\d) hour/i)[0][0].to_i
          if hours_away
            @works_for_count = 0
            @response_count = 0
            @suggested_date = DateTime.now + Rational(hours_away, 24)
            msg.respond("Would #{@suggested_date.strftime('%l')} work for everyone?")
          end
        end
      elsif text.include? 'when should we play?'
        @suggested_date = DateTime.now
        @works_for_count = 0
        @response_count = 0
        msg.respond('Why not right now?')
      end
    end

    @bot.include! Core
  end
end
