#!/usr/bin/ruby

require 'optparse'

require_relative 'lib_pingyam.rb'

def check_string(string)
  string.split(/\s+/).each do |word|
    if !@conv.check_syllable(word)
      puts word
    end
  end
end

def convert_file(options, target)
  filename = options[:filename]
  if !File.exist?(filename)
    abort("  Specified file does not exist: '#{filename}'")
  end
  File.read(filename).each_line do |line|
    pingyam = line.chomp
    puts @conv.convert_line(pingyam, target, options)
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ./convert_pingyam.rb [options]"

  opts.on('-c', '--check', 'Check if input contains invalid Cantonese romanization') { options[:check] = true }
  opts.on('-i', '--input STRING', 'Input string to be converted') { |v| options[:input] = v }
  opts.on('-f', '--filename FILE', 'Provide file for conversion') { |v| options[:filename] = v }
  opts.on('-s', '--source INDEX', 'Provide index number of romanization to convert from') { |v| options[:source] = v }
  opts.on('-S', '--superscript', 'Print tone numerals as superscript') { options[:superscript] = true }
  opts.on('-t', '--target INDEX', 'Provide index number of romanization to convert into') { |v| options[:target] = v }
  opts.on('-Y', '--yale', 'Normalize Yale to 6-tone traditional system') { options[:yale] = true }

end.parse!

if !options[:input] && !options[:filename]
  abort("  Please provide some input text or a filename.")
end

pingyam = options[:input]
target = options[:target]
source = options[:source]

target = target ? target.to_i : 1
source = source ? source.to_i : 0

@conv = Converter.new(source)

if options[:check]
  check_string(pingyam)
elsif options[:filename]
  convert_file(options, target)
else
  puts @conv.convert_line(pingyam, target, options)
end
