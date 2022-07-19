#!/usr/bin/ruby -w

require 'brotli'
require 'date'
require 'json'
require 'nokogiri'
require 'optparse'

RADICAL_NUMBER = /.*\(\#([0-9]*)\).*/
CREDITS_REGEXP = /This \S* has been viewed (\d+) times since (.*?), was added by (.*?) on (.*) and last edited on (.*)/
CREDITS_NO_EDIT_REGEXP = /This \S* has been viewed (\d+) times since (.*?), was added by (.*?) on (.*)/
SENTENCE_CREDITS_REGEXP = /This sentence was added by (.*?) and last edited on (.*)/
LAST_EDITED_REGEXP = /and last edited on/
LEVEL_REGEXP = /Level: \d/
GOOGLE_FREQUENCY_REGEXP = /Google Frequency: (.*)/

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

def new_entry_data(cantodict_id, entry_type)
  return {
    :chinese => nil,
    :entry_type => entry_type,
    :cantodict_id => cantodict_id,
    :definition => nil,
    :definition_raw_html => nil,
    :views => nil,
    :notes => nil,
    :level => nil,
    :jyutping => nil,
    :pinyin => nil,
    :dialect => nil,
    :pos => [],
    :flag => [],
    :incomplete => 0,
    :addedby => nil,
    :created => nil,
    :modified => nil,
    :radical => nil,
    :radical_number => nil,
    :stroke_count => nil,
    :similar => [],
    :variants => [],
    :google_frequency => nil,
    :compound_cantodictids => [],
    :sentence_cantodictids => [],
    :character_cantodictids => []
  }
end

# Compounds that exist in search as well as the related list but which detail pages
# would not be scraped.
MISSING_COMPOUND_50835 = new_entry_data(50835, 'compound').merge({
  :chinese => '過大海',
  :definition => '[港] to go to Macau',
  :definition_raw_html => '<div>[港] to go to Macau</div>',
  :views => 0,
  :notes => '[missing entry]',
  :level => 3,
  :jyutping => 'gwo3 daai6 hoi2',
  :pinyin => 'guo4 da4 hai3',
  :dialect => 1,
  :pos => 'verb',
  :incomplete => 1,
  :variants => '过大海',
  :character_cantodictids => '930,47,26'
})

MISSING_COMPOUND_50837 = new_entry_data(50837, 'compound').merge({
  :chinese => '雜果賓治',
  :definition => 'fruit punch',
  :definition_raw_html => '<div>fruit punch</div>',
  :views => 0,
  :notes => '[missing entry]',
  :level => 3,
  :jyutping => 'jaap6 gwo2 ban1 ji6',
  :pinyin => 'za2 guo3 bin1 zhi4',
  :dialect => 1,
  :pos => 'noun',
  :incomplete => 1,
  :variants => '杂果宾治',
  :character_cantodictids => '892,391,3323,1071'
})

MISSING_COMPOUND_50838 = new_entry_data(50838, 'compound').merge({
  :chinese => '嘢食',
  :definition => 'food',
  :definition_raw_html => '<div>food</div>',
  :views => 0,
  :notes => '[missing entry]',
  :level => 3,
  :jyutping => 'ye5 sik6',
  :pinyin => 'ye3 si4',
  :dialect => 1,
  :pos => 'noun',
  :incomplete => 1,
  :character_cantodictids => '676,116'
})

def get_entrycard(doc, type)
  case type
  when 'character'
    return doc.xpath("//table[contains(@class, 'charactercard')]")
  when 'compound'
    return doc.xpath("//table[contains(@class, 'wordcard')]")
  when 'sentence'
    return doc.xpath("//table[contains(@class, 'sentencecard')]")
  else
    raise "Invalid type #{type}"
  end
end

def process_romanizations(node, entry_data)
  # Handle romanizations
  entry_data[:jyutping] = node.xpath("//span[contains(@class,'cardjyutping')]").text
  entry_data[:pinyin] = node.xpath("//span[contains(@class,'cardpinyin')]").text
end

def process_dialect(node, entry_data)
  if node.classes.include?('typedesc')
    case node.text.strip
      when /This \S+ is used in Cantonese, not Mandarin\/Standard written Chinese./
        entry_data[:dialect] = 'cantonese-only'
      when /This \S+ is used in Mandarin\/Standard written Chinese, not Cantonese./
        entry_data[:dialect] = 'mandarin-or-written-only'
      when /This \S+ is used in both Cantonese and Mandarin\/Standard written Chinese./
        entry_data[:dialect] = 'all'
      else
        entry_data[:dialect] = 'unknown'
    end
    return true
  end

  return false
end

def process_meaning_attributes(node, type, entry_data)
  classes = node.classes
  case type
  when 'character'
    if process_dialect(node, entry_data)
      # Nothing to do.
    elsif classes.include?('charlevel')
      entry_data[:level] = node.text.split(':')[-1].strip.to_i
    else
      return false
    end

  when 'compound', 'sentence'
    if classes.include?('wordlevel')
      node.children.each do |wl_child|
        if process_dialect(wl_child, entry_data)
          # Nothing to do.
        elsif wl_child.name === 'small'
           m = GOOGLE_FREQUENCY_REGEXP.match(wl_child.text.strip)
           if m
             entry_data[:google_frequency] = m[1].split('').reject {|c| c == ','}.join('').to_i
           end
        elsif wl_child.text.strip =~ LEVEL_REGEXP
          entry_data[:level] = wl_child.text.split(':')[-1].strip.to_i
        end
      end
    elsif type == 'sentence' && (node.name == 'script' || node.name === 'center')
        # Skip this. it's the flash player.
    else
      return false
    end
  else
    raise "Invalid type #{type}"
  end

  return true
end

def process_common_meaning_attributes(node, entry_data)
  classes = node.classes
  if classes.include?('charnotes')
    entry_data[:notes] = node.text
  elsif classes.include?('posicon')
    entry_data[:pos] << node.attributes['alt'].value
  elsif classes.include?('flagicon')
    entry_data[:flag] << node.attributes['alt'].value.strip
  elsif classes.include?('charstrokecount')
    stroke_count = node.text.split(':')[-1].strip.to_i
    entry_data[:stroke_count] = stroke_count if stroke_count != 0
  elsif classes.include?('charradical')
    radical = node.xpath(".//span[contains(@class,'chinesemed')]")
    if radical.size > 1
      puts "weird radical #{node.text} for #{filename}"
    end
    unless radical.size < 1
      entry_data[:radical] = radical[0].text.strip
    end
    m = RADICAL_NUMBER.match(node.text) || [nil]
    entry_data[:radical_number] = m[1].to_i
  else
    return false
  end

  return true
end

def process_meaning(node, type, entry_data)
  if type == 'sentence'
    wordmeaning = node.xpath("//td[contains(@class, 'wordmeaning')]/div[contains(@class,'audioplayer')]")[0]
  else
    wordmeaning = node.xpath("//td[contains(@class, 'wordmeaning')]")[0]
  end

  meaning_text = []
  meaning_html = []
  wordmeaning.children.each do |n|
    handled = process_common_meaning_attributes(n, entry_data) ||
              process_meaning_attributes(n, type, entry_data)
    unless handled
      meaning_html << n.to_s
      if n.name === 'br' or n.name === 'hr'
        meaning_text << "\n" if meaning_text.last != "\n"
      else
        stripped = n.text.strip
        unless stripped.empty? || stripped == 'Default PoS:' || stripped == 'Additional PoS:'
          meaning_text << stripped
        end
      end
    end
  end
  entry_data[:definition] = meaning_text.join(' ').squeeze(" \n").squeeze(' ').strip
  entry_data[:definition_raw_html] = "<div>#{meaning_html.join(' ')}</div>".squeeze(' ').strip
end

def process_main_info(node, type, entry_data)
  case type
  when 'character'
    # Handle the similar characters blob
    similar_span = node.xpath("//span[contains(@class,'cd_similar')]")
    entry_data[:similar] = []
    similar_span.xpath('//a[contains(@class, "linkchar")]').each { |n| entry_data[:similar] << n.text }

    # Get the actual chinese
    entry_data[:chinese] = node.xpath("//td[contains(@class,'chinesebigger')]").text.strip
    entry_data[:variants] = node.xpath("//td[contains(@class,'chinesebig')]").text.strip.split.reject { |c| c == entry_data[:chinese] || c.ascii_only? }

  when 'compound'
    entry_data[:chinese] = node.xpath("//span[contains(@class,'word')]")[0].text.strip
    entry_data[:variants] = node.xpath("//td[contains(@class,'chinesebig')]")[0].text.strip.split('/').map {|v| v.strip}.reject {|v| v === entry_data[:chinese]}

  when 'sentence'
    entry_data[:chinese] = node.xpath("//span[contains(@class,'sentence')]")[0].text.strip

  else
    raise "Invalid type #{type}"
  end
end

def process_relations(node, type, entry_data)
  # Find related entries
  case type
  when 'character'
    entry_data[:compound_cantodictids] = node.xpath("//td[contains(@class,'cantodictbg1')]/a[starts-with(@href,'http:')]").map { |n| n.attributes['href'].value.split('/')[-1].to_i }
    entry_data[:sentence_cantodictids] = node.xpath("//td[contains(@class,'cantodictexamplesblock')]/div[contains(@class,'example_in_block')]/a[starts-with(@href,'http:')]").map { |n| n.attributes['href'].value.split('/')[-1].to_i }
  when 'compound'
    entry_data[:character_cantodictids] = node.xpath("//td[contains(@class,'cantodictcharacterblock')]/span/a[starts-with(@href,'http:') and contains(@class,'linkchar')]").map { |n| n.attributes['href'].value.split('/')[-1].to_i }
    entry_data[:compound_cantodictids] = node.xpath("//td[contains(@class,'cantodictcharacterblock')]/span/a[starts-with(@href,'http:') and contains(@class,'wordlink')]").map { |n| n.attributes['href'].value.split('/')[-1].to_i }
    entry_data[:sentence_cantodictids] = node.xpath("//td[contains(@class,'cantodictexamplesblock')]/div[contains(@class,'example_in_block')]/a[starts-with(@href,'http:')]").map { |n| n.attributes['href'].value.split('/')[-1].to_i }
  when 'sentence'
    entry_data[:character_cantodictids] = node.xpath("//td[contains(@class,'cantodictwordblock')]/span/a[contains(@href,'/characters/') and contains(@class,'linkchar')]").map { |n| n.attributes['href'].value.split('/')[-1].to_i }
    entry_data[:compound_cantodictids] = node.xpath("//td[contains(@class,'cantodictwordblock')]/span/a[contains(@href,'/words/') and contains(@class,'linkchar')]").map { |n| n.attributes['href'].value.split('/')[-1].to_i }
  else
    raise "Invalid type #{type}"
  end
end

def process_credits(node, type, entry_data)
  # Handle the credits blob
  credit_string = node.xpath("//span[contains(@class,'credits')]").text.strip

  if type == 'sentence'
    # For some reason sentences do not have a view count.
    credits_match = SENTENCE_CREDITS_REGEXP.match(credit_string)
    entry_data[:addedby] = credits_match[1].strip

    # There's a prettier way to do this but whatever.
    entry_data[:modified] = DateTime.parse(credits_match[2])
  else
    if credit_string =~ LAST_EDITED_REGEXP
      credits_match = CREDITS_REGEXP.match(credit_string)
    else
      credits_match = CREDITS_NO_EDIT_REGEXP.match(credit_string)
    end
    entry_data[:views] = credits_match[1].to_i
    entry_data[:addedby] = credits_match[3].strip

    added_string = credits_match[4].strip
    unless added_string.empty?
      entry_data[:created] = DateTime.parse(added_string)
    end
    if credits_match[5]
      modified_string = credits_match[5].strip
      unless modified_string.empty?
        entry_data[:modified] = DateTime.parse(modified_string)
      end
    end
  end
end

# Find incomplete stuff.
# a =document.evaluate("//*[normalize-space(.) = '*!*!* This entry has been marked as INCOMPLETE by an editor, so it is not fully accurate *!*!*']", document, null,  XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null)

INCOMPLETE_TEXT=%(*!*!* This entry has been marked as INCOMPLETE by an editor, so it is not fully accurate *!*!*)
def process_incomplete(node, entry_data)
  incomplete_nodes = node.xpath("//*[normalize-space(.) = 'INCOMPLETE']")
  entry_data[:incomplete] = 1 if incomplete_nodes.size > 0
end

def parse_html(filename)
  if File.extname(filename) == '.br'
    return Nokogiri::HTML(Brotli.inflate(File.read(filename)))
  end

  return File.open(filename, "r:UTF-8") { |f| Nokogiri::HTML(f.read()) }
end

def process_detail(filename, type)
  doc = parse_html(filename)

  # Get the id
  # TODO: Use domain table.  # 1 for character, 2 for word, 3 for sentence.
  entry_data = new_entry_data(filename.split('-')[-1].split('.')[0].to_i, type)

  # The page has one main character card which is a table with one row for each
  # type of data.
  # TODO: Get this based on type
  entrycard = get_entrycard(doc, type)

  process_main_info(entrycard, type, entry_data)
  process_romanizations(entrycard, entry_data)
  process_meaning(entrycard, type, entry_data)
  process_relations(entrycard, type, entry_data)
  process_credits(entrycard, type, entry_data)
  process_incomplete(entrycard, entry_data)

  return {entry_data[:cantodict_id] => entry_data}
end

SUMMARY_ID_EXTRACT = %r{http://www.cantonese.sheik.co.uk/dictionary/(?:characters|words|examples)/(\d+)/$}
def extract_summary_id(node)
  # Not every compound has an id in the linke. If it starts with english letters,
  # the format is wrong. Instead of indexing 0, search for anchor. If anchor
  # href doesn't match the URL then return nil to indicate odd entry format.
  id_anchor = node.xpath('.//a').first
  if id_anchor
    m = id_anchor.attributes['href'].value.match(SUMMARY_ID_EXTRACT)
    unless m.nil?
      return m[1]
    end
  end

  return nil
end

# Some entries don't have a cantodict_id that is easily scraped.
UNKNOWN_SUMMARY_ID = {
 "BB" => 1601,
 "ㄅㄆㄇㄈ" => 48938,
 "IQ" => 31480,
 "Y5" => 60829,
 "kilo" => 31483,
 "MCC" => 31818, 
 "kai" => 47779,
 "HIGH" => 48361,
 "like" => 47845,
 "pat pat" => 50177,
}
def process_summary(filename, type)
  doc = parse_html(filename)

  results = {}
  case type
  when 'character'
    entries = doc.xpath("//table/tr[td[contains(@class, 'chinese')]]")
  when 'compound'
    entries = doc.xpath("//table/tr[td[contains(@class, 'wl_uni')]]")
  when 'sentence'
    entries = doc.xpath("//table/tr[td/span[contains(@class, 'chinesemed')]]")
  end

  entries.each do |e|
    entry_data = new_entry_data(extract_summary_id(e.elements[0]).to_i, type)

    # Common on all types.
    if ['compound', 'character'].include?(type)
      entry_data[:chinese] = e.elements[0].text.strip
      entry_data[:jyutping] = e.elements[1].text.strip
      entry_data[:pinyin] = e.elements[2].text.strip
      entry_data[:definition] = e.elements[3].text.sub(/\[www.cantonese.sheik.co.uk\]/,'').strip

      if type == 'compound'
        entry_data[:level] = e.elements[5].text.strip.to_i
        entry_data[:addedby] = e.elements[6].text.strip
      end
    elsif type == 'sentence'
      entry_data[:chinese] = e.elements[1].text.strip
      entry_data[:definition] = e.elements[2].text.sub(/\[www.cantonese.sheik.co.uk\]/,'').strip
      entry_data[:level] = e.elements[3].text.strip.to_i
      entry_data[:addedby] = e.elements[4].text.strip
    end

    editbox = e.elements[4].elements
    if editbox.length > 1
      case editbox[0].text.strip
      when '?'
        entry_data[:dialect] = 'unknown'
      when '國'
        entry_data[:dialect] = 'mandarin-or-written-only'
      when '粵'
        entry_data[:dialect] = 'cantonese-only'
      else
        entry_data[:dialect] = 'all'
      end
    end

    # Attempt to backfill the id.
    entry_data[:cantodict_id] = UNKNOWN_SUMMARY_ID[entry_data[:chinese]] if entry_data[:cantodict_id].nil?

    if entry_data[:cantodict_id].nil?
      puts "problem with #{entry_data} in #{filename}"
    else
      results[entry_data[:cantodict_id]] = entry_data
    end
  end

  return results
end

def process_glob(glob)
  results = {}

  Dir.glob(glob).each do |filename|
    begin
      type = File.basename(filename).split('-')[0]
      raise "Invalid type #{type}" unless ['character', 'compound', 'sentence'].include?(type)
      if @options[:mode] == :detail
        data = process_detail(filename, type)
      elsif @options[:mode] == :summary
        data = process_summary(filename, type)
      end
      results.merge!(data)
    rescue Exception => e
      puts filename, e
    end
  end

  return results
end

if ARGV[0]
  puts process_glob(ARGV[0])
else
  if @options[:mode] == :detail
    File.open('output/detail-characters.json', 'w') do |file|
      file.write(process_glob('data/detail/characters/**/*.html.br').to_json)
    end
    File.open('output/detail-compounds.json', 'w') do |file|
      results = process_glob('data/detail/compounds/**/*.html.br')
      results.merge(MISSING_COMPOUND_50835)
      results.merge(MISSING_COMPOUND_50837)
      results.merge(MISSING_COMPOUND_50838)
      file.write(results.to_json)
    end
    File.open('output/detail-sentences.json', 'w') do |file|
      file.write(process_glob('data/detail/sentences/**/*.html.br').to_json)
    end
  elsif @options[:mode] == :summary
    File.open('output/summary-characters.json', 'w') do |file|
      file.write(process_glob('data/summary/characters/**/*.html.br').to_json)
    end
    File.open('output/summary-compounds.json', 'w') do |file|
      file.write(process_glob('data/summary/compounds/**/*.html.br').to_json)
    end
    File.open('output/summary-sentences.json', 'w') do |file|
      file.write(process_glob('data/summary/sentences/**/*.html.br').to_json)
    end
  end
end
