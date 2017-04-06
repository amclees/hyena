require "discordrb"
require "./hyena-secret.rb"

bot = Discordrb::Bot.new token: HyenaSecret.bot_token, client_id: HyenaSecret.client_id

puts "Invite URL is #{bot.invite_url}."

# Simple test, remove later
bot.message(content: /.*hyena/i) do |event|
  event.respond("#{event.content.reverse}")
end

bot.run
