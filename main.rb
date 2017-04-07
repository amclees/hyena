require "discordrb"
require "./hyena-secret.rb"
require "./dice.rb"

bot = Discordrb::Commands::CommandBot.new token: HyenaSecret.bot_token, client_id: HyenaSecret.client_id, prefix: "hyena "

puts "Invite URL is #{bot.invite_url}."

bot.message(content: /(\d*)d(\d*)/i) do |event|
  pair = event.content.scan(/(\d*)d(\d*)/i)[0]
  rolls = pair[0].to_i
  sides = pair[1].to_i
  event.respond("You rolled a #{ Dice.dx(rolls, sides) }")
end

bot.command :commands do |event|
  event.respond(%(
  Type `<number of dice>d<sides>` to roll dice. For example, `1d20`, `4d6`, or `1d100`.
  ))
  nil
end

bot.run :async

bot.set_user_permission(125750053309513728, 100)
bot.send_message(275074190498070530, "**Hello!** I, the *hyena*, have come to roll dice and do other things. Type `hyena commands` to see what I can do for you.")
bot.sync
