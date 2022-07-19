CREATE TABLE IF NOT EXISTS Entries (
  entry_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,

  chinese TEXT,  -- Primary text.
  entry_type TEXT NOT NULL, -- Entry type. character, compound, or sentence
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

  incomplete BOOLEAN -- If the entry is marked as incomplete.

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

  UNIQUE(entry_type, cantodict_id)
);

-- many to one relationship
CREATE TABLE Variants(
  entry_id INTEGER NOT NULL,
  ordering INTEGER NOT NULL,
  chinese TEXT,
  FOREIGN KEY (entry_id) REFERENCES Entries (entry_id)
  CONSTRAINT PK_Variants PRIMARY KEY (entry_id, ordering)
);

CREATE TABLE Similars(
  entry_id INTEGER NOT NULL,
  ordering INTEGER NOT NULL,
  chinese TEXT,
  FOREIGN KEY (entry_id) REFERENCES Entries (entry_id)
  CONSTRAINT PK_Similars PRIMARY KEY (entry_id, ordering)
);

CREATE TABLE RelatedEntries(
  entry_id INTEGER NOT NULL,
  ordering INTEGER NOT NULL,
  entry_type INTEGER NOT NULL, -- Entry type. 1 for character, 2 for word, 3 for sentence
  related_entry_id INTEGER NOT NULL,
  FOREIGN KEY (entry_id) REFERENCES Entries (entry_id)
  FOREIGN KEY (related_entry_id) REFERENCES Entries (entry_id)
  CONSTRAINT PK_RelatedEntries PRIMARY KEY (entry_id, entry_type, ordering)
);

CREATE INDEX IDX_RelatedEntriesEntryType ON RelatedEntries (entry_type);
CREATE INDEX IDX_RelatedEntriesEntryId ON RelatedEntries (entry_id);
