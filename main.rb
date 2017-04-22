require 'discordrb'
require_relative './json_manager.rb'
require_relative './hyena_secret.rb'
require_relative './dice.rb'
require_relative './logger.rb'
require_relative './combat/combat_container.rb'

Logger.log("Starting up")
bot = Discordrb::Commands::CommandBot.new token: HyenaSecret.bot_token, client_id: HyenaSecret.client_id, prefix: "."
Logger.log("Created bot")

JSONManager.init("data")

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
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to roll a #{rolls}d#{sides} but failed due to too many dice.")
  elsif sides > 10_0000_0000
    msg.respond("#{msg.author.display_name}, you can't roll dice with that many sides!")
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to roll a #{rolls}d#{sides} but failed due to too many sided dice.")
  else
    roll = Dice.dx(rolls, sides)
    msg.respond("#{msg.author.display_name}, you rolled a #{ roll } on a #{rolls}d#{sides}")
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) rolled a #{roll} on a #{rolls}d#{sides}")
  end
end

bot.message do |msg|
  Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) said #{msg.content}")
end

bot.command(:exit, help_available: false, permission_level: 100) do |msg|
  Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) issued command to exit.")
  msg.respond("Saving and exiting...")
  Logger.log("Sent exit message")
  scenario_hash.keys.each do |key|
    combat_manager = scenario_hash[key]
    if combat_manager
      JSONManager.write_json("scenarios", combat_manager.json_filename, combat_manager.to_json)
      Logger.log("Saved scenario #{combat_manager.name} owned by UID #{combat_manager.user_id}")
    end
  end
  sleep(0.1) until not Logger.logging
  Logger.save
  msg.respond("Done saving, exiting now.")
  bot.invisible # Causes offline to immediately display
  exit
end

current_game = nil
bot.command(:playing, help_available: false, permission_level: 100) do |msg, arg1, arg2|
  if(arg1 == "on")
    if arg2
      current_game = arg2
    else
      current_game = "D&D"
    end
    bot.game = current_game
    if current_game == "D&D"
      msg.respond("@everyone Session starting, get in voice!")
      server.members.each do |member|
        next if member.bot_account?
        if member.game
          msg.respond("#{member.mention} Stop playing #{member.game} and get on here!")
        end
      end
    end
  else
    current_game = nil
    bot.game = nil
    msg.respond("Session has ended.")
  end
  nil
end

bot.playing do |event|
  if current_game == "D&D" && event.game
    bot.send_message(channel_general.id, "#{event.user.mention} Stop playing #{event.game} and get on here!")
    Logger.log("#{event.user.username} (id: #{event.user.id}) was warned not to play #{event.game}")
  end
end

bot.run :async
Logger.log("Bot started")

channel_general = bot.find_channel("general", nil, type: 0)[0] unless bot.find_channel("general").empty?
server = channel_general.server

bot.set_user_permission(125750053309513728, 100)
if channel_general
  bot.send_message(channel_general.id, "**Hello!** I, the *hyena*, have come to roll dice and do other things. Type `#{bot.prefix}help` to see what I can do for you (other than roll dice).\nType `<number of dice>d<sides>` to roll dice. For example, `1d20`, `4d6`, or `1d100`.")
end
bot.sync
Logger.log("Initialization complete")
