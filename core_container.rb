# frozen_string_literal: false

require_relative './logger.rb'
require_relative './json_manager.rb'

# Core is the container for commands not belonging to other modules.
module Core
  extend Discordrb::Commands::CommandContainer
  @current_game = nil
  @dice_description = <<~DICE_DESCRIPTION
    Type in `<amount>d<sides>` to roll dice. For example, `2d6` or `1d20`.
        You can also use the modifiers `+`, `-`, or `*`. If you put an extra `*` before another modifier it will be applied to each roll (rather than their sum).
        For example, `1d20 + 5`, `4d8 *- 3`, or `20d6 ** 2`.
  DICE_DESCRIPTION

  def self.init(bot, config)
    @bot = bot
    @config = config

    @hyena_intro = <<~HYENA_INTRO
      **Hello!** I, the *hyena*, have come to roll dice and do other things.
      Type `#{bot.prefix}help` to see what I can do for you.
      Type `<number of dice>d<sides>` to roll dice.
      For example, `1d20`, `4d6`, or `1d100`.`
    HYENA_INTRO

    @bot.message do |msg|
      HyenaLogger.log_user(msg.author, "said #{msg.content}")
    end

    @bot.playing do |event|
      if current_game == 'D&D' && event.game
        @bot.send_message(channel_general.id, game_message(member))
        HyenaLogger.log_user(member, "was warned not to play #{event.game}")
      end
    end
  end

  def self.game_message(member)
    "#{member.mention} Stop playing #{member.game} and join the session."
  end

  def self.save
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
  end

  def self.save_and_exit
    save
    # Causes offline status to immediately display.
    @bot.invisible
    exit
  end

  def self.list_logs
    regex = Regexp.new(HyenaLogger.date_format_filename.gsub(/%\w/, '\d+'))
    matched = []
    Dir.entries('./logs').each do |filename|
      match_data = regex.match(filename)
      matched.push(filename) if match_data
    end
    matched.sort.reverse
  end

  command(:intro, description: 'Ask hyena to introduce itself.') do |msg|
    HyenaLogger.log_user(msg.author, 'asked hyena to introduce itself')
    msg.respond(@hyena_intro)
  end

  command(:xdx, description: @dice_description) {}

  command(:exit, help_available: false, permission_level: 100) do |msg|
    HyenaLogger.log_user(msg.author, 'issued command to exit.')
    msg.respond('Saving and exiting.')
    HyenaLogger.log('Sent exit message.')
    save_and_exit
  end

  command(:save, help_available: false, permission_level: 100) do |msg|
    save
    HyenaLogger.log_user(msg.author, 'saved all data.')
    msg.respond('Saved.')
  end

  command(:playing, help_available: false, permission_level: 100) do |msg, arg1, arg2, arg3|
    server = msg.author.respond_to?(:server) ? msg.author.server : nil
    if arg1 == 'on'
      @current_game = arg2 ? arg2 : 'D&D'
      @current_game = 'D&D' if arg2 == 'sil'
      @bot.game = @current_game
      if server && @current_game == 'D&D' && !(arg2 == 'sil' || arg3)
        msg.respond('@everyone Session starting, get in voice!')
        server.members.each do |member|
          next if member.bot_account?
          msg.respond(game_message(member)) if member.game
        end
      end
    else
      msg.respond('Session has ended.') if @current_game == 'D&D' && arg1 != 'sil'
      @current_game = nil
      @bot.game = nil
    end
    nil
  end

  command(:ignore, help_available: false, permission_level: 100) do |msg, arg1|
    server = msg.author.respond_to?(:server) ? msg.author.server : nil
    if server
      to_ignore = nil
      server.members.each do |member|
        if member.id.to_s == arg1
          to_ignore = member
          break
        end
      end
      if to_ignore
        if @bot.ignored?(to_ignore)
          @bot.unignore_user(to_ignore)
          msg.respond('Successfully unignored')
          HyenaLogger.log_user(msg.author, "removed #{arg1} from ignore list.")
        else
          @bot.ignore_user(to_ignore)
          msg.respond('Successfully ignored')
          HyenaLogger.log_user(msg.author, "added #{arg1} to ignore list.")
        end
      else
        msg.respond('That was not a valid user, please try again.')
      end
    else
      msg.respond('Try again after connecting to a server.')
    end
    nil
  end

  command(:logs, help_available: false, permission_level: 100) do |msg, arg1|
    logs = list_logs
    page_number = arg1 ? arg1.to_i : 1
    page_number -= 1 if page_number
    page_size = 10
    if page_number && page_number >= 0 && page_number * page_size < logs.length
      to_display = logs.slice(page_number * page_size, 10).each_with_index.map do |filename, index|
        "Log \##{index + (page_size * page_number) + 1} #{filename}"
      end
      log_string = to_display.join("\n")
      msg.respond("Logs - Page #{page_number + 1} of #{(logs.length / page_size) + 1}\n```\n#{log_string}\n```")
      HyenaLogger.log_user(msg.author, "displayed pages #{page_number + 1} through #{(logs.length / page_size) + 1} of logs")
    else
      msg.respond('That is not a valid page number')
      HyenaLogger.log_user(msg.author, 'tried to view logs but gave an invalid page number')
    end
  end

  command(
    :log,
    help_available: false,
    permission_level: 100,
    bucket: :file_cmd,
    rate_limit_message: 'Try again in %time% more seconds.'
  ) do |msg, arg1|
    logs = list_logs
    log_number = arg1.to_i
    if log_number && log_number.positive? && log_number <= logs.length
      log_number -= 1
      filename = logs[log_number]
      msg.respond("Log \##{log_number + 1}")
      HyenaLogger.log_user(msg.author, "retrieved log #{filename}")
      msg.channel.send_file(File.new("./logs/#{filename}"))
    else
      msg.respond('That is not a valid log.')
    end
  end

  command(%i[online on], help_available: false, permission_level: 100) do
    @bot.online
    HyenaLogger.log_user(msg.author, 'set hyena status to online')
    nil
  end

  command(:dnd, help_available: false, permission_level: 100) do
    @bot.dnd
    HyenaLogger.log_user(msg.author, 'set hyena status to do not disturb')
    nil
  end

  command(:invisible, help_available: false, permission_level: 100) do
    @bot.invisible
    HyenaLogger.log_user(msg.author, 'set hyena status to invisible')
    nil
  end

  command(:away, help_available: false, permission_level: 100) do
    @bot.away
    HyenaLogger.log_user(msg.author, 'set hyena status to away')
    nil
  end
end
