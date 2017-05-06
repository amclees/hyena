# frozen_string_literal: false

require 'date'

# Handles logging and saving logs.
module HyenaLogger
  @logs = []
  @logging = false
  @debug = true
  @since = DateTime.now
  @save_interval = 300
  @date_format = '%Y-%m-%d-%H:%M:%S'
  @date_format_filename = '%Y-%m-%d-%H-%M-%S'

  def self.debug=(value)
    @debug = value if !!value == value
    @debug = false if value.nil?
  end

  def self.save_interval=(interval)
    @save_interval = interval
  end

  def self.date_format=(new_format)
    @date_format = new_format
  end

  def self.date_format_filename=(new_format)
    @date_format_filename = new_format
  end

  def self.logging
    @logging
  end

  def self.start_thread
    Dir.mkdir('logs') unless File.directory?('logs')
    Thread.new do
      loop do
        sleep(@save_interval)
        save
      end
    end
  end

  def self.save
    return if @logs.empty? || @logging
    @logging = true
    write_log
    @logging = false
  end

  def self.write_log
    filename = DateTime.now.strftime("hyena-#{@date_format_filename}.log")
    puts "Writing ./logs/#{filename}"
    file = File.new("./logs/#{filename}", 'w')
    from = @since.strftime(@date_format)
    to = DateTime.now.strftime(@date_format)
    file.syswrite("This log covers the time from #{from} to #{to}\n"\
      "#{@logs.join("\n")}")
    file.close
    @logs = []
    @since = DateTime.now
  end

  def self.log(message)
    to_log = "[#{DateTime.now.strftime(@date_format)}] #{message}"
    @logs << to_log
    puts to_log if @debug
  end

  # action: <verb (past tense)> <noun phrase>
  def self.log_member(member, action)
    log("#{member.display_name} (id: #{member.id}) #{action}")
  end

  private_class_method :write_log
end

HyenaLogger.start_thread
