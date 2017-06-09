# frozen_string_literal: false

require 'json'
require_relative './dice.rb'

# Dice Command Handler
module DiceContainer
  extend Discordrb::Commands::CommandContainer

  @dice_description = <<~DICE_DESCRIPTION
    Type in `<amount>d<sides>` to roll dice. For example, `2d6` or `1d20`.

        You can use the modifiers `+`, `-`, or `*`. If you put an extra `*` before another modifier it will be applied to each roll (rather than their sum).
        For example,
          `4d6 ** 2` rolls 4 6-sided dice, multiplying each by 2.
          `2d20 + 5` rolls 2 20-sided dice, then adds 5 to their **sum** (not each die).
          `2d20 *+ 5` works as above, but adds 5 to **each roll**.

        You can omit the number of dice to roll 1 (e.g. `d20`).

        You can drop the lowest dice from a roll by adding `dX` to the end of the roll, where `X` is the number of dice you would like to drop.
        For example,
          `4d6d1` rolls 4 6-sided dice and totals the three highest rolls.
          `2d20 ** -2 d1` rolls 2 20-sided dice subtracting 2 from each roll, then drops the lowest roll.
  DICE_DESCRIPTION

  @dice_regex = nil
  @ability_score_distribution = nil

  def self.init(bot)
    @bot = bot
    ability_score_distribution_json = JSONManager.read_json('dice_distributions', 'ability_scores.json')
    if ability_score_distribution_json
      @ability_score_distribution = JSON.parse(ability_score_distribution_json)
      @total_scores = @ability_score_distribution.values.inject(:+)
      @ability_score_keys_sorted = @ability_score_distribution.keys.map(&:to_i).sort
    end

    @dice_regex = /\A\s*(?:#{Regexp.quote(bot.prefix)})?\s*(\d+)?\s*d\s*(\d+)\s*(?:(\*?[*+-])\s*(\d+))?\s*(?:d\s*(\d+))?\s*\z/i

    bot.message(content: @dice_regex) do |msg|
      params = msg.content.scan(@dice_regex)[0]
      rolls = params[0] ? params[0].to_i : 1
      sides = params[1].to_i
      operator = params[2] ? params[2] : '+'
      # If not included, to_i will make nil into 0.
      modifier = params[3].to_i
      to_drop = params[4].to_i

      array_roll = (2..200).cover?(rolls) && (1..1000).cover?(sides)

      roll_string = "#{rolls}d#{sides}"
      roll_string += "#{operator}#{modifier}" unless operator == '+' && modifier.zero?
      roll_string += "d#{to_drop}" unless to_drop.zero?

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
        roll = Dice.total_with_drop(roll_array, to_drop)
        roll = Dice.modified_roll(roll, modifier, operator) unless apply_all
        multiplying = operator[1] == '*'
        roll_table = Dice.generate_roll_table(roll_array, Dice.modified_roll(sides, modifier, operator), multiplying ? modifier : 1)
        max_message = roll_array.include?(Dice.modified_roll(sides, modifier, operator)) ? "\n\nYou rolled a natural #{Dice.get_emoji_str(sides)} :heart_eyes:" : ''
        response = "#{roll_table}\n#{msg.author.username}, you rolled a #{Dice.get_emoji_str(roll)} on a #{roll_string}#{max_message}\nYour average roll was #{Dice.get_emoji_str(Dice.avg(roll_array))}"
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

    @bot.include! DiceContainer
  end

  command(:dice, description: @dice_description) do |msg|
    HyenaLogger.log_user(msg.author, 'requested dice description')
    msg.respond(@dice_description)
  end

  command(
    :ability,
    description: <<~ABILITY_SCORE_DESCRIPTION
      Roll 6 ability scores.
      Each is a 4d6d1 just as it would be if rolled manually, but all scores will be displayed with modifiers.
    ABILITY_SCORE_DESCRIPTION
  ) do |msg|
    HyenaLogger.log_user(msg.author, 'rolled ability scores')
    response = ''
    scores = []
    6.times do |time|
      rolls = Dice.dx_array(4, 6)
      rolls = rolls.sort
      score = Dice.total_with_drop(rolls)
      scores.push(score)
      response << "Roll \##{time + 1}\n```#{rolls.join(' ')}```\nYour score is #{score}\n\n"
    end
    scores.sort!
    emoji_scores = scores.map do |score|
      Dice.get_emoji_str(score)
    end
    modifiers = scores.map do |score|
      ((score.to_f - 10.0) / 2.0).floor
    end
    emoji_modifiers = modifiers.map do |modifier|
      Dice.get_emoji_str(modifier)
    end
    average = 73.46
    total_score = scores.inject(:+)
    total_modifiers = modifiers.inject(:+)
    response << <<~SCORES
      -------------------------------------------------------------------------------------------------------

      Your scores are #{emoji_scores.join('   ')}
      Your modifiers are #{emoji_modifiers.join('   ')}
      The total of you scores and modifiers are #{total_score} and #{total_modifiers} respectively.
    SCORES
    if @ability_score_distribution
      total_exceeded = 0
      @ability_score_keys_sorted.each do |key|
        break if key >= total_score
        total_exceeded += @ability_score_distribution[key.to_s]
      end
      percentile = ((total_exceeded.to_f / @total_scores) * 100).round(2)
      descriptor = percentile < 50 ? 'worse' : 'better'
      percentile = 100 - percentile if percentile < 50
      response << <<~ANALYSIS

        You total score is #{((total_score.to_f / average) * 100).round(2)}% of the average (The average total score is #{average}).
        You rolled #{descriptor} than #{percentile}% of people.
      ANALYSIS
      response << "\nTypically, you would qualify for rerolling your scores (since they are too low)." if scores.max <= 13 || !total_modifiers.positive?
    end
    msg.respond(response)
  end
end
