# frozen_string_literal: false

require 'discordrb'
require 'yaml'
require_relative './json_manager.rb'
require_relative './dice.rb'
require_relative './logger.rb'
require_relative './combat/combat_container.rb'

HyenaLogger.log('Started running main.')

CONFIG = YAML.load_file('config.yaml')

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

scenario_hash = {}
Combat.init(bot.prefix, scenario_hash)
bot.include! Combat

bot.message(content: /(\d*)d(\d*)/i) do |msg|
  pair = msg.content.scan(/(\d*)d(\d*)/i)[0]
  rolls = pair[0].to_i
  sides = pair[1].to_i
  if rolls > 1000
    msg.respond("#{msg.author.display_name}, you can't roll that many dice!")
    HyenaLogger.log_member(msg.author, "attempted to roll a #{rolls}d#{sides} "\
    "but failed due to too many dice.")
  elsif sides > 1_000_000_000
    msg.respond("#{msg.author.display_name}, you can't roll dice with that "\
    "many sides!")
    HyenaLogger.log_member(msg.author, "attempted to roll a #{rolls}d#{sides}"\
    " but failed due to too many sided dice.")
  else
    roll = Dice.dx(rolls, sides)
    msg.respond("#{msg.author.display_name}, you rolled a #{ roll } on a "\
    " #{rolls}d#{sides}")
    HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) rolled"\
    " a #{roll} on a #{rolls}d#{sides}")
  end
end

bot.message do |msg|
  HyenaLogger.log_member(msg.author, "said #{msg.content}")
end

bot.command(:exit, help_available: false, permission_level: 100) do |msg|
  HyenaLogger.log_member(msg.author, 'issued command to exit.')
  msg.respond('Saving and exiting...')
  HyenaLogger.log('Sent exit message.')
  scenario_hash.keys.each do |key|
    combat_manager = scenario_hash[key]
    if combat_manager
      JSONManager.write_json(
        'scenarios',
        combat_manager.json_filename,
        combat_manager.to_json
      )
      HyenaLogger.log("Saved scenario #{combat_manager.name} owned by UID "\
      "#{combat_manager.user_id}")
    end
  end
  sleep(0.1) while HyenaLogger.logging
  HyenaLogger.save
  msg.respond('Done saving, exiting now.')
  # Causes offline status to immediately display
  bot.invisible
  exit
end

def game_message(member)
  "#{member.mention} Stop playing #{member.game} and join the session."
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

bot.set_user_permission(125750053309513728, 100)
if channel_general
  bot.send_message(
    channel_general.id,
    <<~HYENA_INTRO
      **Hello!** I, the *hyena*, have come to roll dice and do other things.
      Type `#{bot.prefix}help` to see what I can do for you.
      Type `<number of dice>d<sides>` to roll dice.
      For example, `1d20`, `4d6`, or `1d100`.
    HYENA_INTRO
  )
end
bot.sync
HyenaLogger.log('Initialization completed.')
