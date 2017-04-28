# frozen_string_literal: false

require 'date'

# Handles logging and saving logs.
module HyenaLogger
  @@logs = []
  @@logging = false
  @@debug = true
  @@since = DateTime.now

  def self.logging
    @@logging
  end

  def self.start_thread
    Dir.mkdir('logs') unless File.directory?('logs')
    Thread.new do
      loop do
        sleep(300)
        save
      end
    end
  end

  def self.save
    return if @@logs.empty? || @@logging
    @@logging = true
    write_log
    @@logging = false
  end

  def self.write_log
    filename = DateTime.now.strftime('hyena-%d-%m-%Y-%H-%M-%S.log')
    puts "Writing ./logs/#{filename}"
    file = File.new("./logs/#{filename}", 'w')
    from = @@since.strftime('%d-%m-%Y-%H:%M:%S')
    to = DateTime.now.strftime('%d-%m-%Y-%H:%M:%S')
    file.syswrite("This log covers the time from #{from} to #{to}\n"\
      "#{@@logs.join('\n')}")
    file.close
    @@logs = []
    @@since = DateTime.now
  end

  def self.log(message)
    to_log = "[#{DateTime.now.strftime('%d-%m-%Y %H:%M:%S')}] #{message}"
    @@logs << to_log
    puts to_log if @@debug
  end

  # action: <verb (past tense)> <noun phrase>
  def self.log_member(member, action)
    log("#{member.display_name} (id: #{member.id}) #{action}")
  end

  private_class_method :write_log
end

HyenaLogger.start_thread
