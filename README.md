# cantodict-archive
Archive of the abandoned Cantonese Dictionary cantodict from https://www.cantonese.sheik.co.uk/dictionary/.

This is an attempt to save the cantodict dataset as the project seems abandoned.
It is an incredible dictionary consisting of lots of works from many volunteers
over years. Letting it bitrot would be a major waste.

## Copyright and License
The code is licensed under CC4.0 attribution. The dictionary data is a scrape of public contributions
where the most prolific author (bybell) that contributed over 53% of the entries in the dictionary
has [explicitly allowed](http://www.cantonese.sheik.co.uk/phorum/read.php?14,151821,151826#msg-151826)
the republication.

Furthermore, the active members of this project has forked a version into
[Cantoneseplus](https://www.cantoneseplus.com/) which intends to keep info public.

Given that Cantonese is a waning language and Cantodict provides a snapshot history
of usage, it feels important to preserve it. That veteran members of the project
believe there is not a problem with a scrape, I'm repulbishing the data here.

## Install
```
bundle install --path vendor/bundle
```

## Tools created
  1. `pages-to-json.rb` -- Takes downloaded webpages and outputs a json version of the entires.
  2. `json-to-sqlite.rb` -- Takes the output json files for characters, compounds, and sentences and then loads them into an sqlite database.
  3. `make-dict.rb` -- Takes the sqlite database and produces dictionary files of various formats. Initially .df files usable by dictutil to create Kobo dictionaries, and an opf directory usable by Kindle Previewer to create a .mobi file for use on kindles.

## Data files
Data files are full screpes of entry detail pages and word list from the cantodict website (see Scrape Method).

Files are compressed using brotli. This yields significant savings over gzip so it was worth the more esoteric archival format.

## Scrape Method
Cantodict looks to be a simple database frontend with REST style URL structre
rendering characters, compounds, and sentences based on the primary key of the
entry.

Entries are of the form
`http://www.cantonese.sheik.co.uk/dictionary/[type]/[id]/`.

A character URL example:
`http://www.cantonese.sheik.co.uk/dictionary/characters/389/` for
character number 389, which is 香.

A compound URL example is:
`http://www.cantonese.sheik.co.uk/dictionary/words/61652/` for compound
number 61652 which is 鑒識.

Sentences URL example is:
`http://www.cantonese.sheik.co.uk/dictionary/examples/741/` for sentence
number 741 which is 做咩你咁慢㗎?.

Getting the full list of is is a little harder. It is pretty much
sequential (See Stats section below for totals of each) but there are holes.
The site itself has some scripts that produce lists of all entries. Here
are the relevant ones.

All Characters (there is no single query):
`http://www.cantonese.sheik.co.uk/scripts/masterlist.htm?level=1`
`http://www.cantonese.sheik.co.uk/scripts/masterlist.htm?level=2`
`http://www.cantonese.sheik.co.uk/scripts/masterlist.htm?level=3`
`http://www.cantonese.sheik.co.uk/scripts/masterlist.htm?level=4`
`http://www.cantonese.sheik.co.uk/scripts/masterlist.htm?action=unsure`

All Compounds
`http://www.cantonese.sheik.co.uk/scripts/wordlist.htm?action=&wordtype=0&level=-1&page=0`

All Sentences (notice level=-1 and wordtype=0).
`http://www.cantonese.sheik.co.uk/scripts/examplelist.htm?level=-1&wordtype=0&filter_by_audio=0&page=0`

Scraping was done by walking through all of the lists to create initial data.
After that, each individiual detail page is walked to fill in missing info.
Then all every missing "id" from 1 to the last entry id for each type was
queried and inspected for missing characters.


## Cantodict Stats

Stats from when this was scraped

| Entry type | L1 | L2| L3 | L4 | L5 | L6 | Total |
|Characters	|71	|702	|1282	|2622	|698	|0	|5372|
|Compound Words	|642	|496	|3835	|44189	|10321	|1610	|60719|
|Example Sentences	|30	|223|	|531|	|722|	|72|	0|	1548|
|Examples with Audio	 	|84|	|184|	|159|	|6|	0|	433|

```
Num Editors: 81
```

## Character pages.
The general structure is

```
//*[@id="container"]/div[1]/center/table[1]
<body>
  <div id="container">
    <table>...nav stuff..</table>
    <br>
    <div>
      <center>
        <center>..ad stuff.. </center>
        <small>..ad stuff.. </small>
        <table class="cardborder charactercard">
          <tr><td>
            <span class="cardjyutping">gau<span class="tone">2</span></span>
            <span class="cardpinyin">jiu<span class="tone">3</span></span>
          </td></tr>

          <tr><td class="wordmeaning">
            [1] nine [2] [Wu] unit for distance
              <!-- note this may have a flagicon for "Archaic Name Obsolete Place" -->
            <div class="charnotes">
              Hyperlinked blob of text explaining variants, etc. May link to other characters.
            </div>
            Default PoS: <img alt="noun">
            Additional PoS: <img alt="adjecetive">
            <div class="charstrokecount">Stroke Count: 2"</div>
            <div class="charlevel">Stroke Count: 1"</div>
            <div class="charradical"><span class="chinesemed"><a href="http://www.cantonese.sheik.co.uk/scripts/wordsearch.php?searchtype=8&radical_num=5">乙</a></span></div>
            <span class="typedesc">"This character is used in both Cantonese and Mandarin/Standard written Chinese."</span>
          </td></tr>

          <tr><td class="chinesebig">箇 / 个</td></tr> <!-- If simplified, it has a slash. 九 only has one codepoint. 后 / 后 has a repeat since it simplifies to itself. -->

          <span class="cd_similar">
             <a href="http://www.cantonese.sheik.co.uk/dictionary/characters/661/" class="linkchar">丸</a>
             <!-- repeated anchors with class=linkchar -->
          </span>

          <span class="credits">
          This word has been viewed 1 times since 30th Oct 2012, was added by sheik on 18th Mar 2007 21:22 and last
          <a href="http://www.cantonese.sheik.co.uk/scripts/editlog.htm?filter=九" title="See list of all edits for this entry">edited</a>
          on 10th Jul 2009 17:06
          </span>

          <tr><td>High res image + vocab list</td></tr>
          <tr><td>Sponsors</td></tr>
          <tr><td class="white cantodictbg1">
            <hr>
            <a href="href="http://www.cantonese.sheik.co.uk/dictionary/words/1400/"></a>
            <span>...bunches of spans for related compounds</spans>

            <br>
            <a href="href="http://www.cantonese.sheik.co.uk/dictionary/words/185/"></a>
            <span>...bunches of spans for related compounds</spans>
            
            [etc]
          </td></tr>

          <tr><td class="white cantodictexamplesblock">
            <div class="example_in_block">
              <a href="http://www.cantonese.sheik.co.uk/dictionary/examples/1046/">
                 ...
            </div>
            <div class="example_in_block">
              <a href="http://www.cantonese.sheik.co.uk/dictionary/examples/1252/">
                 ...
            </div>
          </td></tr>

        </table>
      </center>
    </div>
  </div>
</body>
```
