#!/usr/bin/ruby

require 'fileutils'
require 'open-uri'

def check_db(file_path)
  File.exist?(file_path) ? true : false
end

def update_db(file_path, new_db)
  FileUtils.mkdir_p "pingyam"
  File.open(file_path, "w") { |f| f << new_db }
end

url = "https://raw.githubusercontent.com/kfcd/pingyam/master/pingyambiu"

new_db = URI.open(url).read

file_path = "./pingyam/pingyambiu"

if check_db(file_path)
  old_db = File.read(file_path)
  if old_db == new_db
    puts "  There are no changes in the database."
  else
    puts "  Updating database..."
    update_db(file_path, new_db)
  end
else
  update_db(file_path, new_db)
end
