require 'date'

class Logger
  @@logs = []
  @@logging = false
  @@debug = true
  @@since = DateTime.now

  def self.logging
    @@logging
  end

  def self.start_thread
    Dir.mkdir("logs") unless File::directory?("logs")
    Thread.new do
      while true do
        sleep(300)
        self.save
      end
    end
  end

  def self.save
    unless @@logs.empty? or @@logging
      @@logging = true
      filename = DateTime.now.strftime("hyena-%d-%m-%Y-%H-%M-%S.log")
      puts "Writing ./logs/#{filename}"
      file = File.new("./logs/#{filename}", "w")
      from = @@since.strftime("%d-%m-%Y-%H:%M:%S")
      to = DateTime.now.strftime("%d-%m-%Y-%H:%M:%S")
      file.syswrite("This log covers the time from #{from} to #{to}\n#{@@logs.join("\n")}")
      file.close
      @@logs = []
      @@since = DateTime.now
      @@logging = false
    end
  end

  def self.log(message)
    toLog = "[#{ DateTime.now.strftime("%d-%m-%Y %H:%M:%S")}] #{message}"
    @@logs << toLog
    puts toLog if @@debug
  end
end

Logger.start_thread
