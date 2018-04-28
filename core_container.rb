# frozen_string_literal: false

require_relative './logger.rb'
require_relative './json_manager.rb'
require 'open-uri'

# Core is the container for commands not belonging to other modules.
module Core
  extend Discordrb::Commands::CommandContainer
  @current_game = nil
  @mimic_hash = {}

  def self.init(bot, config)
    @bot = bot
    @voice_bot = nil
    @config = config

    @hyena_intro = <<~HYENA_INTRO
      **Hello!** I, the *hyena*, have come to roll dice and do other things.
      Type `#{bot.prefix}help` to see what I can do for you.
      Type `<number of dice>d<sides>` to roll dice.
      For example, `1d20`, `4d6`, or `1d100`.
    HYENA_INTRO

    @paused = false

    @bot.message do |msg|
      HyenaLogger.log_user(msg.author, "said #{msg.content}")
    end

    @bot.message do |msg|
      if @mimic_hash.key?(msg.author.id) && @mimic_hash[msg.author.id]
        msg.respond(msg.content)
      end
    end

    @bot.playing do |event|
      if @current_game == 'D&D' && event.game
        @bot.send_message(channel_general.id, game_message(member))
        HyenaLogger.log_user(member, "was warned not to play #{event.game}")
      end
    end

    @bot.include! Core
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
    @voice_bot&.destroy
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

  def self.track_list
    matched = []
    regex = /\A.*\.(?:ogg|mp3|m4a)\z/i

    Dir.chdir('data') do
      Dir.mkdir('audio') unless File.directory?('audio')
    end

    Dir.entries('./data/audio').each do |filename|
      match_data = regex.match(filename)
      matched.push(filename) if match_data
    end
    matched.sort
  end

  command(:intro, description: 'Ask hyena to introduce itself.') do |msg|
    HyenaLogger.log_user(msg.author, 'asked hyena to introduce itself')
    msg.respond(@hyena_intro)
  end

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

  command(:playing, help_available: false, permission_level: 100) do |msg, arg1, *args|
    arg2 = args.join(' ')
    server = msg.author.respond_to?(:server) ? msg.author.server : nil
    if arg1 == 'on'
      @current_game = arg2 ? arg2 : 'D&D'
      @current_game = 'D&D' if arg2 == 'sil'
      @bot.game = @current_game
      if server && @current_game == 'D&D' && arg2 != 'sil'
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
      total_pages = (logs.length.to_f / page_size.to_f).ceil
      msg.respond("Logs - Page #{page_number + 1} of #{total_pages}\n```\n#{log_string}\n```")
      HyenaLogger.log_user(msg.author, "displayed pages #{page_number + 1} through #{total_pages} of logs")
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
    if log_number&.positive? && log_number <= logs.length
      log_number -= 1
      filename = logs[log_number]
      msg.respond("Log \##{log_number + 1}")
      HyenaLogger.log_user(msg.author, "retrieved log #{filename}")
      msg.channel.send_file(File.new("./logs/#{filename}"))
    else
      msg.respond('That is not a valid log.')
    end
  end

  command(%i[set_status ss], help_available: false, permission_level: 100) do |msg, arg1|
    valid_status = true

    case arg1
    when 'online'
      @bot.online
    when 'dnd'
      @bot.dnd
    when 'invisible'
      @bot.invisible
    when 'away'
      @bot.away
    else
      valid_status = false
    end

    if valid_status
      HyenaLogger.log_user(msg.author, "set hyena status to #{arg1}")
    else
      HyenaLogger.log_user(msg.author, 'tried to set hyena status to an invalid value')
    end
    nil
  end

  command(:mimic, help_available: false, permission_level: 100) do |msg, arg1|
    arg1 = arg1.to_i
    return if arg1.zero?
    @mimic_hash[arg1] = @mimic_hash.key?(arg1) ? !@mimic_hash[arg1] : true
    HyenaLogger.log_user(msg.author, "set hyena to#{@mimic_hash[arg1] ? '' : ' not'} mimic id #{arg1}")
    msg.respond("Toggling mimic on #{arg1}")
    nil
  end

  command(:voice, help_available: false, permission_level: 100) do |msg, action, channel_name|
    if action == 'connect'
      channel = nil
      server = msg.server.name
      channel = @bot.find_channel(channel_name, server, type: 2)[0] unless @bot.find_channel(channel_name, server, type: 2).empty?
      if channel
        @voice_bot = @bot.voice_connect(channel)
        msg.respond("Successfully connected to channel #{channel_name}")
      else
        msg.respond('Channel not found')
      end
    elsif action == 'disconnect'
      if @voice_bot
        @voice_bot.destroy
        msg.respond('Disconnected')
      else
        msg.respond('Not connected to a voice channel')
      end
    end
    nil
  end

  command(:tracks, help_available: false, permission_level: 100) do |msg|
    msg.respond("```\n#{track_list.join("\n")}\n```")
    HyenaLogger.log_user(msg.author, 'listed all available tracks')
    nil
  end

  command(:play, help_available: false, permission_level: 100) do |msg, arg1|
    return unless @voice_bot
    existing_track = track_list.find { |possible_track| possible_track == arg1 }
    if existing_track
      msg.respond('Playing now')
      msg.voice.play_file("./data/audio/#{existing_track}")
      HyenaLogger.log_user(msg.author, "started playback of #{existing_track}")
    else
      msg.respond('That track was not found. Please use the `tracks` command to find valid tracks.')
    end
    nil
  end

  command(:pause, help_available: false, permission_level: 100) do |msg|
    return unless @voice_bot
    if @paused
      msg.voice.continue
      HyenaLogger.log_user(msg.author, 'unpaused the stream')
    else
      msg.voice.pause
      HyenaLogger.log_user(msg.author, 'paused the stream')
    end
    @paused = !@paused
    nil
  end

  command(:stop, help_available: false, permission_level: 100) do |msg|
    return unless @voice_bot
    msg.voice.stop_playing
    HyenaLogger.log_user(msg.author, 'stopped the current stream')
    nil
  end

  command(:skip, help_available: false, permission_level: 100) do |msg, arg1|
    return unless @voice_bot
    seconds = arg1.to_i
    return unless seconds.positive? && seconds < 86_400
    HyenaLogger.log_user(msg.author, "skipped #{arg1} seconds in the current stream")
    msg.voice.skip(seconds)
    nil
  end

  command(:stream_time, help_available: false, permission_level: 100) do |msg|
    return unless @voice_bot
    stream_time = 0
    stream_time = @voice_bot.stream_time.round(2) if @voice_bot.stream_time
    HyenaLogger.log_user(msg.author, 'displayed the current stream time')
    msg.respond("The current stream has been running #{stream_time} seconds.")
    nil
  end

  command(:volume, help_available: false, permission_level: 100) do |msg, arg1|
    return unless @voice_bot
    volume = arg1.to_f
    return unless volume < 10 && !volume.negative?
    HyenaLogger.log_user(msg.author, "set playback volume to #{arg1}")
    msg.voice.volume = volume
    nil
  end

  command(:await_upload, help_available: false, permission_level: 100) do |msg|
    msg.author.await(:file_upload, {}) do |file_message|
      next true if file_message.message.content == 'cancel'

      next false if file_message.message.attachments.empty?
      attachment = file_message.message.attachments[0]
      next false if /\A.*\.(?:ogg|mp3|m4a)\z/i.match(attachment.filename).nil?

      # open-url redefines open from the Kernel module
      open("./data/audio/#{attachment.filename}", 'wb') do |file|
        file << open(attachment.url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
      end

      file_message.respond('Successfully received file')
      next true
    end
    HyenaLogger.log_user(msg.author, 'set an await for an audio upload')
    msg.respond('Waiting for audio upload...')
    nil
  end

  command(:play_url, help_available: false, permission_level: 100) do |msg, arg1|
    return unless @voice_bot
    HyenaLogger.log_user(msg.author, "played url: #{arg1}")
    msg.respond('Playing now')
    msg.voice.play_io(open(arg1, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE))
    nil
  end
end
