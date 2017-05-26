# frozen_string_literal: false

# Handles reading and writing JSON data for each module
module JSONManager
  def self.valid_filename?(name)
    %r{\A[^\/\\\?%\*:|"<>]+\z}.match(name)
  end

  def self.init(folder_name)
    Dir.mkdir(folder_name) unless File.directory?(folder_name)
    @json_folder = folder_name
  end

  def self.write_json(subfolder, filename, json)
    Dir.chdir(@json_folder) do
      Dir.mkdir(subfolder) unless File.directory?(subfolder)
      Dir.chdir(subfolder) do
        File.open(filename, 'w') do |file|
          file.syswrite(json)
        end
      end
    end
  end

  def self.read_json(subfolder, filename)
    return nil unless exist?(subfolder, filename)
    json = nil
    Dir.chdir(@json_folder) do
      Dir.mkdir(subfolder) unless File.directory?(subfolder)
      Dir.chdir(subfolder) do
        File.open(filename, 'r') do |file|
          file.each_line do |line|
            json = '' unless json
            json = line
          end
        end
      end
    end
    json
  end

  # Returns an array of all the first capture groups of the regex
  def self.search(subfolder, regex)
    matched = []
    Dir.chdir(@json_folder) do
      Dir.mkdir(subfolder) unless File.directory?(subfolder)
    end
    Dir.entries("./#{@json_folder}/#{subfolder}").each do |filename|
      match_data = regex.match(filename)
      matched.push(match_data.captures[0]) if match_data
    end
    matched
  end

  def self.exist?(subfolder, filename)
    exists = nil
    Dir.chdir(@json_folder) do
      if File.directory?(subfolder)
        Dir.chdir(subfolder) do
          exists = File.exist?(filename)
        end
      end
    end
    exists
  end

  def self.delete_json(subfolder, filename)
    json = nil
    Dir.chdir(@json_folder) do
      Dir.mkdir(subfolder) unless File.directory?(subfolder)
      Dir.chdir(subfolder) do
        if File.exist?(filename)
          File.open(filename, 'r') do |file|
            file.each_line do |line|
              json = '' unless json
              json = line
            end
          end
          File.delete(filename)
        end
      end
    end
    json
  end
end
