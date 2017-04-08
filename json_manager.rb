
module JSONManager
  def self.init(folder_name)
    Dir.mkdir(folder_name) unless File::directory?(folder_name)
    @@json_folder = folder_name
  end

  def self.write_json(subfolder, filename, json)
    Dir.chdir(@@json_folder) do
      Dir.mkdir(subfolder) unless File::directory?(subfolder)
      Dir.chdir(subfolder) do
        File.open(filename, "w") do |file|
          file.syswrite(json)
        end
      end
    end
  end

  def self.read_json(subfolder, filename)
    json = nil
    Dir.chdir(@@json_folder) do
      Dir.chdir(subfolder) do
        File.open(filename, "r").each_line do |line|
          json = line
          break
        end
      end
    end
    json
  end
end
