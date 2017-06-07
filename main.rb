# frozen_string_literal: false

require 'discordrb'
require 'yaml'
require_relative './logger.rb'
require_relative './core_container.rb'
require_relative './dice_container.rb'
require_relative './combat/combat_container.rb'
require_relative './world/world_container.rb'

HyenaLogger.log('Started running main.')

if File.exist?('config.yml')
  CONFIG = YAML.load_file('config.yml')
elsif File.exist?('config.yaml')
  CONFIG = YAML.load_file('config.yaml')
else
  puts 'No config.yml or config.yaml found, please create one with your bot_token and client_id.'
  exit
end

HyenaLogger.save_interval = CONFIG['log_save_interval'] if CONFIG.key?('log_save_interval')
HyenaLogger.debug = CONFIG['debug'] if CONFIG.key?('debug')
HyenaLogger.date_format = CONFIG['date_format'] if CONFIG.key?('date_format')
HyenaLogger.date_format_filename = CONFIG['date_format_filename'] if CONFIG.key?('date_format_filename')

admin_ids = CONFIG.key?('admin_ids') ? CONFIG['admin_ids'] : []
prefix = CONFIG.key?('prefix') ? CONFIG['prefix'] : '.'

bot = Discordrb::Commands::CommandBot.new(
  token: CONFIG['bot_token'],
  client_id: CONFIG['client_id'],
  prefix: prefix
)
HyenaLogger.log('Created bot.')

JSONManager.init(CONFIG.key?('data_folder') ? CONFIG['data_folder'] : 'data')

puts "Invite URL is #{bot.invite_url}."

# File commands are limited to admins, so abuse of them should be limited.
bot.bucket :file_cmd, limit: 3, time_span: 15, delay: 5

DiceContainer.init(bot)

Combat.init(bot)

WorldContainer.init(bot, CONFIG)

Core.init(bot, CONFIG)

bot.run :async
HyenaLogger.log('Bot started.')

admin_ids.each do |admin_id|
  bot.set_user_permission(admin_id, 100)
end

bot.sync
HyenaLogger.log('Initialization completed.')
