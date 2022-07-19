#!/usr/bin/ruby -w

require "json"
require "sqlite3"
require 'optparse'

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

TABLE_CREATE_SQL = <<HEREDOC
CREATE TABLE IF NOT EXISTS EntryTypes (
  entry_type TEXT PRIMARY KEY
);

INSERT OR IGNORE INTO EntryTypes(entry_type) VALUES('character');
INSERT OR IGNORE INTO EntryTypes(entry_type) VALUES('compound');
INSERT OR IGNORE INTO EntryTypes(entry_type) VALUES('sentence');

CREATE TABLE IF NOT EXISTS Dialects (
  dialect TEXT PRIMARY KEY
);
INSERT OR IGNORE INTO Dialects(dialect) VALUES('cantonese-only');
INSERT OR IGNORE INTO Dialects(dialect) VALUES('mandarin-or-written-only');
INSERT OR IGNORE INTO Dialects(dialect) VALUES('all');
INSERT OR IGNORE INTO Dialects(dialect) VALUES('unknown');

CREATE TABLE IF NOT EXISTS %{prefix}Entries (
  entry_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,

  chinese TEXT,  -- Primary text.
  entry_type INTEGER NOT NULL, -- Entry type. 1 for character, 2 for word, 3 for sentence
  cantodict_id INTEGER NOT NULL,

  -- Common attributes
  definition TEXT,  -- English definition.
  definition_raw_html TEXT,  -- English definition but without the HTML markup removed.
  notes TEXT, -- Notes about the entry, often clarifications on the definition.
  level INTEGER, -- cantodict difficulty level.
  jyutping TEXT, --  Jyutping romanization. Tone numbers.
  pinyin TEXT,  -- pinyin romanization. Tone numbers.
  dialect TEXT, -- 1 for Cantonese only, 2 for Mandarin/Standard Written Cantonese Only, 3 for both
  pos TEXT, -- Comma separated list for part of speech. First is the "Default" PoS according to Cantodict.
  flag TEXT, -- Comman separated list for extra classification atttributes about the entry. Examples: Archaic, Place
  views INTEGER, -- Number of views since 30th Oct 2012

  addedby TEXT, -- Userid of editor that added the entry.
  created DATE, -- When entry was added if available.
  modified DATE,  -- Last edit time if available.

  incomplete BOOLEAN, -- If the entry is marked as incomplete.

  -- Character attributes
  radical TEXT, -- radical if it is a character
  radical_number INTEGER, -- Kangxi radical number
  stroke_count INTEGER, -- Number of strokes in the character

  -- Compound attributes
  google_frequency INTEGER, -- Weird google frequency stat from cantodict

  -- List of related entries.
  similar TEXT, -- Comma separated list of similar entries.
  variants TEXT, -- Comma separated list of variants for the entry. Most frequently it's simplified.
  character_cantodictids TEXT, -- Comma separated list of related characters in order of the cantodict detail page
  compound_cantodictids TEXT, -- Comma separated list of related compounds in order of the cantodict detail page
  sentence_cantodictids TEXT, -- Comma separated list of related sentences in order of the cantodict detail page

  FOREIGN KEY (entry_type) REFERENCES EntryTypes (entry_type)
  FOREIGN KEY (dialect) REFERENCES Dialects (dialect)
  UNIQUE(entry_type, cantodict_id)
);

-- many to one relationship
CREATE TABLE IF NOT EXISTS %{prefix}Variants(
  entry_id INTEGER NOT NULL,
  ordering INTEGER NOT NULL,
  chinese TEXT,
  FOREIGN KEY (entry_id) REFERENCES Entries (entry_id)
  CONSTRAINT PK_%{prefix}Variants PRIMARY KEY (entry_id, ordering)
);

CREATE TABLE IF NOT EXISTS %{prefix}Similars(
  entry_id INTEGER NOT NULL,
  ordering INTEGER NOT NULL,
  chinese TEXT,
  FOREIGN KEY (entry_id) REFERENCES %{prefix}Entries (entry_id)
  CONSTRAINT PK_%{prefix}Similars PRIMARY KEY (entry_id, ordering)
);

CREATE TABLE IF NOT EXISTS %{prefix}RelatedEntries(
  entry_id INTEGER NOT NULL,
  ordering INTEGER NOT NULL,
  entry_type INTEGER NOT NULL, -- Entry type. 1 for character, 2 for word, 3 for sentence
  related_entry_id INTEGER NOT NULL,
  FOREIGN KEY (entry_id) REFERENCES %{prefix}Entries (entry_id)
  FOREIGN KEY (related_entry_id) REFERENCES %{prefix}Entries (entry_id)
  CONSTRAINT PK_%{prefix}RelatedEntries PRIMARY KEY (entry_id, entry_type, ordering)
);

CREATE INDEX IF NOT EXISTS IDX_%{prefix}RelatedEntriesEntryType ON %{prefix}RelatedEntries (entry_type);
CREATE INDEX IF NOT EXISTS IDX_%{prefix}RelatedEntriesEntryId ON %{prefix}RelatedEntries (entry_id);
HEREDOC

def load_json(mode)
  data = {}
  [:characters, :compounds, :sentences].each do |type|
    File.open("./output/#{mode}-#{type}.json") { |f| data[type] = JSON.load(f) }
  end
  return data
end


INSERT_SQL = <<HEREDOC
INSERT INTO %{prefix}Entries
(chinese, entry_type, cantodict_id, definition, definition_raw_html, views,
 notes, level, jyutping, pinyin, dialect, pos, flag, incomplete, addedby,
 created, modified, radical, radical_number, stroke_count, similar, variants,
 google_frequency, compound_cantodictids, sentence_cantodictids,
 character_cantodictids)
VALUES
(:chinese, :entry_type, :cantodict_id, :definition, :definition_raw_html,
  :views, :notes, :level, :jyutping, :pinyin, :dialect, :pos, :flag,
  :incomplete, :addedby, :created, :modified, :radical, :radical_number,
  :stroke_count, :similar, :variants, :google_frequency,
  :compound_cantodictids, :sentence_cantodictids, :character_cantodictids)
HEREDOC

def csv_or_nil(list)
  list ? list.join(',') : nil
end

def load_data(db, sql_params, entries)
  begin
    insert_stmt = db.prepare(INSERT_SQL % sql_params)
    entries.each do |id, entry|
      id = id.to_i
      if id != entry['cantodict_id']
        puts "Skipping invalid entry at '#{id}' which mismatches --#{entry['cantodict_id']}--"
        return
      end
      begin
        params = entry.clone()

        # Turn fields into CSV
        params['pos'] = csv_or_nil(params['pos'])
        params['flag'] = csv_or_nil(params['flag'])
        params['similar'] = csv_or_nil(params['similar'])
        params['variants'] = csv_or_nil(params['variants'])
        params['character_cantodictids'] = csv_or_nil(params['character_cantodictids'])
        params['compound_cantodictids'] = csv_or_nil(params['compound_cantodictids'])
        params['sentence_cantodictids'] = csv_or_nil(params['sentence_cantodictids'])

        insert_stmt.execute(params)
      rescue Exception => e
        puts "Failed inserting #{id}. Error: '#{e}' params: #{params}"
      end
    insert_stmt.reset!
    end
  ensure
    insert_stmt.close if insert_stmt
  end
end

# Validate
begin
  dbfile = ARGV[0]
  unless dbfile
    dbfile = 'output/cantodict.sqlite'
  end

  mode = @options[:mode]
  if mode == :detail
    db_params = {:prefix => ''}
  elsif mode == :summary
    db_params = {:prefix => 'Summary'}
  end

  data = load_json(mode)

  db = SQLite3::Database.new dbfile
  db.transaction

  db.execute_batch(TABLE_CREATE_SQL % db_params)
  [:characters, :compounds, :sentences].each do |type|
    load_data(db, db_params, data[type])
  end

  db.commit
ensure
  if db
    db.rollback if db.transaction_active?
    db.close
  end
end
