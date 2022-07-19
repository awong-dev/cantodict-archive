#!/usr/bin/ruby -w 

# This creates dictionary files

require "sqlite3"
require 'optparse'
require_relative "pingyam-rb/lib_pingyam.rb"

@options = {:romanization => :yale, :incomplete => true, :vulgar => true, :format => :kobo}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0}"

  opts.on("-j", "--jyutping", "jyutping romanizaiton [default is yale]") { |n| @options[:romanization] = :jyutping }

  opts.on("-c", "--complete-only", "skip incomplete entries") { |n| @options[:incomplete] = false }
  opts.on("-n", "--nice", "no vulgar words") { |n| @options[:vulgar] = false }

  opts.on("-a", "--kindle", "make kindle dictionary format [default kobo df]") { |n| @options[:format] = :kindle }

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

def make_dictname
  name = "cantodict-#{@options[:romanization]}"
  name += '-no-incomplete' unless @options[:incomplete]
  name += '-no-vulgar' unless @options[:vulgar]
  return name
end

CoverHtml = <<HEREDOC
<html>
  <head>
    <meta content="text/html" http-equiv="content-type">
  </head>
  <body>
    <h1>Cantodict (v. %s)</h1>
    <h2>A Collaborative Dictionary of Cantonese from https://www.cantonese.sheik.co.uk/</h2>
    <h3>Created by Cantodict editors over the years</h3>
  </body>
</html>
HEREDOC

CopyrightHtml = <<HEREDOC
<html>
  <head>
    <meta content="text/html" http-equiv="content-type">
  </head>
  <body>
    <h1>Copyright</h1>
    <h3>Cantodict editors from https://www.cantonese.sheik.co.uk/</h3>
    <ul>
      <li>bybell -- 36397</li>
      <li>tym -- 7297</li>
      <li>sheik -- 5327</li>
      <li>Michael 忠仔 -- 4747</li>
      <li>Steph_fr -- 3631</li>
      <li>C Chiu -- 1922</li>
      <li>WANNABEAFREAK -- 1399</li>
      <li>claw -- 1256</li>
      <li>bernard -- 778</li>
      <li>yuetwoh -- 616</li>
      <li>radagasty -- 527</li>
      <li>Eldon -- 493</li>
      <li>nanimo -- 463</li>
      <li>Yeegs -- 453</li>
      <li>aaron -- 335</li>
      <li>穆斯林 -- 244</li>
      <li>rathpy -- 202</li>
      <li>tuan -- 196</li>
      <li>kath -- 154</li>
      <li>riko -- 137</li>
      <li>XieChengnuo -- 133</li>
      <li>yckillua -- 108</li>
      <li>spacemonkey -- 93</li>
      <li>wai ming -- 82</li>
      <li>duaaagiii -- 72</li>
      <li>goofygreg -- 65</li>
      <li>AliceWong -- 61</li>
      <li>SophusNg -- 60</li>
      <li>MrBug -- 59</li>
      <li>Emerald -- 53</li>
      <li>beLIEve -- 47</li>
      <li>Kobo-Daishi -- 45</li>
      <li>jsrwang -- 43</li>
      <li>Cryme -- 40</li>
      <li>theABC -- 38</li>
      <li>SaNgUi -- 37</li>
      <li>ray_siu -- 34</li>
      <li>changeup -- 30</li>
      <li>dr.slump -- 29</li>
      <li>platinumangel -- 26</li>
      <li>14K Guy -- 23</li>
      <li>azurenights -- 18</li>
      <li>BenoniH -- 17</li>
      <li>atyh1985 -- 16</li>
      <li>desmond -- 15</li>
      <li>s.m. -- 13</li>
      <li>Honna -- 13</li>
      <li>Antje -- 13</li>
      <li>supermidget -- 12</li>
      <li>hkl8324 -- 12</li>
      <li>Wonton -- 12</li>
      <li>Shusaku -- 11</li>
      <li>rschmitt -- 10</li>
      <li>anthony -- 10</li>
      <li>alanl -- 10</li>
      <li>carson -- 9</li>
      <li>a-dat -- 7</li>
      <li>asiancajun -- 6</li>
      <li>ChaakMing -- 6</li>
      <li>wilson -- 4</li>
      <li>registered99 -- 4</li>
      <li>makiaea -- 4</li>
      <li>RichardSharpe -- 4</li>
      <li>Zac2333 -- 3</li>
      <li>ProsperousBridge -- 3</li>
      <li>velshin -- 2</li>
      <li>takeru -- 1</li>
      <li>romano -- 1</li>
    </ul>
  </body>
</html>
HEREDOC

CantodictOpf = <<HEREDOC
<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId">
  <metadata>
    <dc:title>Cantodict (v. %s)</dc:title>
    <dc:creator opf:role="aut">Cantodict editors from https://www.cantonese.sheik.co.uk/</dc:creator>
    <dc:language>zh</dc:language>
    <meta name="cover" content="my-cover-image" />
    <x-metadata>
      <DictionaryInLanguage>zh</DictionaryInLanguage>
      <DictionaryOutLanguage>en</DictionaryOutLanguage>
      <DefaultLookupIndex>cantodict</DefaultLookupIndex>
    </x-metadata>
  </metadata>
  <manifest>
    <!-- <item href="cover-image.jpg" id="my-cover-image" media-type="image/jpg" /> -->
    <item id="cover"
          href="cover.html"
          media-type="application/xhtml+xml" />
    <item id="copyright"
          href="copyright.html"
          media-type="application/xhtml+xml" />
    <item id="content"
          href="content.html"
          media-type="application/xhtml+xml" />
  </manifest>
  <spine>
    <itemref idref="cover" />
    <itemref idref="copyright"/>
    <itemref idref="content"/>
  </spine>
  <guide>
    <reference type="index" title="IndexName" href="content.html"/>
  </guide>
</package>
HEREDOC

DictionaryStart =<<HEREDOC
<html xmlns:math="http://exslt.org/math" xmlns:svg="http://www.w3.org/2000/svg" xmlns:tl="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf"
xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns:cx="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf" xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:mbp="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf" xmlns:mmc="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf" xmlns:idx="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf">
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body>
<mbp:frameset>
HEREDOC

DictionaryEnd = <<HEREDOC
</mbp:frameset>
</body>
</html>
HEREDOC

EntryStart =<<HEREDOC
<idx:entry name="cantodict" scriptable="yes" spell="yes">
<idx:short><a id="%{id}"></a>
<idx:orth value="%{headword}">%{headword} - %{short_description}
HEREDOC

EntryEnd =<<HEREDOC
</idx:orth>
<p>%{definition}</p>
</idx:short>
</idx:entry>
HEREDOC

@conv = Converter.new(6)

def get_dict_data(definition_join_char_, attribute_join_char_)
  begin
    dbfile = ARGV[0]
    dbfile = 'output/cantodict.sqlite' unless dbfile
    db = SQLite3::Database.new dbfile
    db.transaction

    entries = []

    target_romanization = 1
    target_romanization = 6 if @options[:romanization] == :jyutping

    db.execute("SELECT chinese, cantodict_id, definition, notes, pos, flag, jyutping, pinyin, dialect, incomplete, radical, stroke_count, variants, similar FROM Entries where entry_type in ('character', 'compound')") do |row|
      chinese, cantodict_id, definition, notes, pos, flag, jyutping, pinyin, dialect, incomplete, radical, stroke_count, variants, similar = row

      next if (not @options[:vulgar]) && flag.split(',').include?("Vulgar")
      next if (not @options[:incomplete]) && incomplete == 1

      romanization = @conv.convert_line(jyutping, target_romanization)
      short_description = "#{romanization}"
      short_description += " [拼 #{pinyin}]" if pinyin
      short_description += " #{radical}" if radical
      short_description += " [粵]" if dialect == 'cantonese-only'
      short_description += " [國]" if dialect == 'mandarin-or-written-only'
      short_description += " INCOMPLETE" if incomplete == 1

      definition_lines = []
      definition_lines << definition.gsub("\r","").strip
      definition_lines << notes.gsub("\r","").strip if notes
      definition_body = definition_lines.join("<br />")

      attributes = []
      attributes << "Pos: #{pos.strip} " unless pos.strip.empty?
      attributes << "strokes: #{stroke_count} " if stroke_count
      attributes << "Similar: #{similar} " if similar and not similar.split(',').empty?
      definition_body += attributes.join("<br />") unless attributes.empty?

      entries << {
        headword: chinese,
        id: cantodict_id,
        variants: variants.split(','),
        short_description: short_description,
        definition: definition_body }

    end

    return entries
  ensure
    if db
      db.rollback if db.transaction_active?
      db.close
    end
  end
end

def make_kindle_dir(entries)
  dictname = make_dictname()
  directory_name = "output/#{dictname}/kindle-#{dictname}"
  Dir.mkdir(directory_name) unless File.exist?(directory_name)

  File.open(directory_name + "/copyright.html", "w") { |f| f.write(CopyrightHtml) }
  File.open(directory_name + "/cover.html", "w") { |f| f.write(CoverHtml % dictname) }
  File.open(directory_name + "/cantodict.opf", "w") { |f| f.write(CantodictOpf % dictname) }
  File.open(directory_name + "/content.html", "w") do |f|
    f.print DictionaryStart
    entries.each do |entry|
      f.print EntryStart % entry
      variants = entry[:variants]
      if variants and variants.size > 0
        f.puts "<idx:infl>"
        variants.each {|v| f.puts %(<idx:iform value="#{v}"></idx:iform>)}
        f.puts "</idx:infl>"
      end
      f.print EntryEnd % entry
    end
    f.print DictionaryEnd
  end
end

def make_kobo_dictfile(entries)
  dictname = make_dictname()
  filename = "output/#{dictname}/kobo-#{dictname}.df"
  File.open(filename, "w") do |f|
    entries.each do |entry|
      f.puts("@#{entry[:headword]}")
      f.puts(":" + entry[:short_description])
      variants = entry[:variants]
      variants.each { |v| f.puts("&#{v}") } if variants and variants.size > 0
      f.puts(entry[:definition])
      f.puts("Cantodict id: #{entry[:id]}")
    end
  end
end

if @options[:format] == :kobo
  entries = get_dict_data("\n", " ")
  make_kobo_dictfile(entries)
elsif @options[:format] == :kindle
  entries = get_dict_data("<br />", "<br />")
  make_kindle_dir(entries)
end
