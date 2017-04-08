require 'discordrb'
require_relative './json_manager.rb'
require_relative './hyena_secret.rb'
require_relative './dice.rb'
require_relative './logger.rb'

Logger.log("Starting up")
bot = Discordrb::Commands::CommandBot.new token: HyenaSecret.bot_token, client_id: HyenaSecret.client_id, prefix: "hyena "
Logger.log("Created bot")

JSONManager.init("data")

puts "Invite URL is #{bot.invite_url}."

channel_general = 275074190498070530

bot.bucket :file_cmd, limit: 3, time_span: 120, delay: 5

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

bot.command(:exit, chain_usable: false, help_available: false, permission_level: 100) do |msg|
  Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) issued command to exit.")
  bot.send_message(channel_general, "Leaving now.")
  Logger.log("Send exit message")
  sleep(0.1) until not Logger.logging
  Logger.save
  exit
end

bot.run :async
Logger.log("Bot started")

bot.set_user_permission(125750053309513728, 100)
bot.send_message(channel_general, "**Hello!** I, the *hyena*, have come to roll dice and do other things. Type `#{bot.prefix}help` to see what I can do for you (other than roll dice).\nType `<number of dice>d<sides>` to roll dice. For example, `1d20`, `4d6`, or `1d100`.")
bot.sync
Logger.log("Initialization complete")
