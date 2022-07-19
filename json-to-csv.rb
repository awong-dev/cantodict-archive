require "json"
require "csv"
require 'optparse'
require_relative "pingyam-rb/lib_pingyam.rb"

@options = {:mode => :detail}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [-s] [glob]"

  opts.on("-s", "--summaries", "[glob] represents cantodict summary pages scrapres, not detail page scrapes") do |n|
    @options[:mode] = :summary
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

Columns = [
  "entry_type",
  "cantodict_id",
  "incomplete",
  "chinese",
  "definition",
  "notes",
  "jyutping",
  "yale",
  "pinyin",
  "radical",
  "radical_number",
  "stroke_count",
  "dialect",
  "similar",
  "variants",
  "pos",
  "flag",
  "addedby",
  "created",
  "modified",
  "views",
  "level",
  "compound_cantodictids",
  "sentence_cantodictids",
  "character_cantodictids",
  "definition_raw_html",
  "google_frequency"
  ]

conv = Converter.new(6)
CSV.open("output/cantodict.csv", "wb") do |csv|
  csv << Columns
  
  [:characters, :compounds, :sentences].each do |type|
    File.open("./output/#{@options[:mode]}-#{type}.json") do |f|
      entries = JSON.load(f)
      entries.keys.sort.each do |id|
        data = entries[id]
        data["yale"] = conv.convert_line(data["jyutping"], 1) 
        csv << Columns.map { |c| data[c] }
      end
    end
  end
end
