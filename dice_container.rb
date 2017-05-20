# frozen_string_literal: false

require_relative './dice.rb'

# Dice Command Handler
module DiceContainer
  extend Discordrb::Commands::CommandContainer

  def self.init(bot)
    bot.message(content: Dice.dice_regex) do |msg|
      params = msg.content.scan(Dice.dice_regex)[0]
      rolls = params[0] ? params[0].to_i : 1
      sides = params[1].to_i
      operator = params[2] ? params[2] : '+'
      # If not included, to_i will make nil into 0.
      modifier = params[3].to_i

      array_roll = (2..200).cover?(rolls) && (1..1000).cover?(sides)

      roll_string = "#{rolls}d#{sides}"
      roll_string += "#{operator}#{modifier}" unless operator == '+' && modifier.zero?

      if (!array_roll && !(operator == '+' || operator == '-')) || (array_roll && (modifier.abs > 100 || (modifier.abs * sides > 1000 && operator[1] == '*')))
        msg.respond("#{msg.author.username}, you can't roll dice with that modifier.")
        HyenaLogger.log_user(msg.author, "attempted to roll a #{roll_string} but failed due to invalid modifiers.")
        next
      end

      if sides > 1_000_000_000
        msg.respond("#{msg.author.username}, you can't roll dice with that many sides!")
        HyenaLogger.log_user(msg.author, "attempted to roll a #{roll_string} but failed due to too many sided dice.")
      elsif array_roll
        apply_all = operator[0] == '*' && operator[1]
        roll_array = Dice.dx_array(rolls, sides, apply_all ? modifier : 0, apply_all ? operator : '+')
        roll = roll_array.inject(:+)
        roll = Dice.modified_roll(roll, modifier, operator) unless apply_all
        multiplying = operator[1] == '*'
        roll_table = Dice.generate_roll_table(roll_array, Dice.modified_roll(sides, modifier, operator), multiplying ? modifier : 1)
        max_message = roll_array.include?(Dice.modified_roll(sides, modifier, operator)) ? "\n\nYou rolled a natural #{Dice.get_emoji_str(sides)} :heart_eyes:" : ''
        response = "#{roll_table}\n#{msg.author.username}, you rolled a #{Dice.get_emoji_str(roll)} on a #{roll_string}#{max_message}"
        if response.length <= 2000
          msg.respond(response)
          HyenaLogger.log_user(msg.author, "rolled a #{roll} on a #{roll_string}")
        else
          msg.respond('Your roll table was too big for Discord to display. Please try again with a different roll.')
          HyenaLogger.log_user(msg.author, "rolled a #{roll} on a #{roll_string}, but the message was over 2000 characters.")
        end
      else
        roll = Dice.dx(rolls, sides, modifier, operator)
        message = "#{msg.author.username}, you rolled a #{Dice.get_emoji_str(roll)} on a #{roll_string}"
        reversed_roll = rolls == 1 ? Dice.inverted_roll(roll, modifier, operator) : nil
        message += "\nYou rolled a natural :one: :stuck_out_tongue_winking_eye:" if reversed_roll == 1
        message += "\nYou rolled a natural #{Dice.get_emoji_str(sides)} :heart_eyes:" if reversed_roll == sides
        msg.respond(message)
        HyenaLogger.log_user(msg.author, "rolled a #{roll} on a #{roll_string}")
      end
    end
  end
end
