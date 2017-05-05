# frozen_string_literal: false

require 'discordrb'
require 'yaml'
require_relative './json_manager.rb'
require_relative './dice.rb'
require_relative './logger.rb'
require_relative './combat/combat_container.rb'

HyenaLogger.log('Started running main.')

if File.exist?('config.yml')
  CONFIG = YAML.load_file('config.yml')
elsif File.exist?('config.yaml')
  CONFIG = YAML.load_file('config.yaml')
else
  puts 'No config.yml or config.yaml found, please create one with your bot_token and client_id.'
  exit
end

HyenaLogger.save_interval = CONFIG['log-save-interval'] if CONFIG.key?('log-save-interval')

admin_ids = CONFIG.key?('log-save-interval') ? CONFIG['admin_ids'] : []

bot = Discordrb::Commands::CommandBot.new(
  token: CONFIG['bot_token'],
  client_id: CONFIG['client_id'],
  prefix: '.'
)
HyenaLogger.log('Created bot.')

JSONManager.init('data')

puts "Invite URL is #{bot.invite_url}."

bot.bucket :file_cmd, limit: 3, time_span: 120, delay: 5

server = nil
channel_general = nil

Combat.init(bot.prefix)
bot.include! Combat

hyena_intro = <<~HYENA_INTRO
  **Hello!** I, the *hyena*, have come to roll dice and do other things.
  Type `#{bot.prefix}help` to see what I can do for you.
  Type `<number of dice>d<sides>` to roll dice.
  For example, `1d20`, `4d6`, or `1d100`.`
HYENA_INTRO

bot.command(:intro, description: 'Ask hyena to introduce itself.') do |msg|
  msg.respond(hyena_intro)
end

bot.command(:xdx, description: 'Type in `<amount>d<sides>` to roll dice.')

bot.message(content: Dice.dice_regex) do |msg|
  params = msg.content.scan(Dice.dice_regex)[0]
  rolls = params[0].to_i
  sides = params[1].to_i
  operator = params[2] ? params[2] : '+'
  # If not included, to_i will make nil into 0.
  modifier = params[3].to_i

  array_roll = (2..200).cover?(rolls) && (1..1000).cover?(sides)

  roll_string = "#{rolls}d#{sides}"
  roll_string += "#{operator}#{modifier}" unless operator == '+' && modifier.zero?

  if (!array_roll && !(operator == '+' || operator == '-')) || (array_roll && (modifier.abs > 100 || (modifier.abs * sides > 1000 && operator[1] == '*')))
    msg.respond("#{msg.author.display_name}, you can't roll dice with that modifier.")
    HyenaLogger.log_member(msg.author, "attempted to roll a #{roll_string} but failed due to invalid modifiers.")
    next
  end

  if sides > 1_000_000_000
    msg.respond("#{msg.author.display_name}, you can't roll dice with that many sides!")
    HyenaLogger.log_member(msg.author, "attempted to roll a #{roll_string} but failed due to too many sided dice.")
  elsif array_roll
    apply_all = operator[0] == '*' && operator[1]
    roll_array = Dice.dx_array(rolls, sides, apply_all ? modifier : 0, apply_all ? operator : '+')
    roll = roll_array.inject(:+)
    roll = Dice.modified_roll(roll, modifier, operator) unless apply_all
    multiplying = operator[1] == '*'
    roll_table = Dice.generate_roll_table(roll_array, Dice.modified_roll(sides, modifier, operator), multiplying ? modifier : 1)
    max_message = roll_array.include?(sides) ? "\n\nYou rolled a natural #{Dice.get_emoji_str(sides)} :heart_eyes:" : ''
    msg.respond("#{roll_table}\n#{msg.author.display_name}, you rolled a #{Dice.get_emoji_str(roll)} on a #{roll_string}#{max_message}")
    HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) rolled a #{roll} on a #{roll_string}")
  else
    roll = Dice.dx(rolls, sides, modifier, operator)
    message = "#{msg.author.display_name}, you rolled a #{Dice.get_emoji_str(roll)} on a #{roll_string}"
    message = 'You rolled a natural :one: :stuck_out_tongue_winking_eye:' if roll == 1
    message = "You rolled a natural #{Dice.get_emoji_str(sides)} :heart_eyes:" if roll == sides
    msg.respond(message)
    HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) rolled a #{roll} on a #{roll_string}")
  end
end

bot.message do |msg|
  HyenaLogger.log_member(msg.author, "said #{msg.content}")
end

def game_message(member)
  "#{member.mention} Stop playing #{member.game} and join the session."
end

def save_and_exit(bot)
  scenario_hash = Combat.scenario_hash
  scenario_hash.keys.each do |key|
    combat_manager = scenario_hash[key]
    next unless combat_manager
    JSONManager.write_json(
      'scenarios',
      combat_manager.json_filename,
      combat_manager.to_json
    )
    HyenaLogger.log("Saved scenario #{combat_manager.name} owned by UID #{combat_manager.user_id}")
  end
  sleep(0.1) while HyenaLogger.logging
  HyenaLogger.save
  # Causes offline status to immediately display
  bot.invisible
  exit
end

bot.command(:exit, help_available: false, permission_level: 100) do |msg|
  HyenaLogger.log_member(msg.author, 'issued command to exit.')
  msg.respond('Saving and exiting.')
  HyenaLogger.log('Sent exit message.')
  save_and_exit(bot)
end

current_game = nil
bot.command(:playing, help_available: false, permission_level: 100) do |msg, arg1, arg2|
  if arg1 == 'on'
    current_game = arg2 ? arg2 : 'D&D'
    bot.game = current_game
    if current_game == 'D&D'
      msg.respond('@everyone Session starting, get in voice!')
      server.members.each do |member|
        next if member.bot_account?
        msg.respond(game_message(member)) if member.game
      end
    end
  else
    current_game = nil
    bot.game = nil
    msg.respond('Session has ended.')
  end
  nil
end

bot.playing do |event|
  if current_game == 'D&D' && event.game
    bot.send_message(channel_general.id, game_message(member))
    HyenaLogger.log_member(member, "was warned not to play #{event.game}")
  end
end

bot.run :async
HyenaLogger.log('Bot started.')

unless bot.find_channel('general').empty?
  channel_general = bot.find_channel('general', nil, type: 0)[0]
end

server = channel_general.server

admin_ids.each do |admin_id|
  bot.set_user_permission(admin_id, 100)
end

bot.sync
HyenaLogger.log('Initialization completed.')
