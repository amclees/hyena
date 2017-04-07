require 'date'

class Logger
  @@logs = []
  @@logging = false
  @@debug = true

  def self.logging
    @@logging
  end

  def self.start_thread
    Dir.mkdir("logs") unless File::directory?("logs")
    Thread.new do
      while true do
        sleep(300)
        unless @@logs.empty?
          @@logging = true
          puts "Writing ./logs/#{DateTime.now.strftime("hyena-%d-%m-%Y-%H:%M:%S")}.log"
          file = File.new("./logs/#{DateTime.now.strftime("hyena-%d-%m-%Y-%H:%M:%S")}.log", "w")
          file.syswrite("#{@@logs.join("\n")}")
          file.close
          @@logs = []
          @@logging = false
        end
      end
    end
  end

  def self.log(message)
    toLog = "[#{ DateTime.now.strftime("%d-%m-%Y %H:%M:%S")}] #{message}"
    @@logs << toLog
    puts toLog if @@debug
  end
end

Logger.start_thread
