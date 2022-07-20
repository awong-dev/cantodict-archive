#!/bin/bash

# Generate all the yale dictionaries.
bundle exec ruby make-dict.rb -a
bundle exec ruby make-dict.rb -a -c
bundle exec ruby make-dict.rb -a -n
bundle exec ruby make-dict.rb -a -c -n

# Generate all the jyutping dictionaries.
bundle exec ruby make-dict.rb -a -j
bundle exec ruby make-dict.rb -a -j -c
bundle exec ruby make-dict.rb -a -j -n
bundle exec ruby make-dict.rb -a -j -c -n

# kindlegen binary can be found from Kindle Previewer https://www.amazon.com/Kindle-Previewer/b?ie=UTF8&node=21381691011
# Run this 

kindlegen -o cantodict-jyutping-no-incomplete-no-vulgar.mobi output/cantodict-jyutping-no-incomplete-no-vulgar/kindle-cantodict-jyutping-no-incomplete-no-vulgar/cantodict.opf
kindlegen -o cantodict-jyutping-no-incomplete.mobi output/cantodict-jyutping-no-incomplete/kindle-cantodict-jyutping-no-incomplete/cantodict.opf
kindlegen -o cantodict-jyutping-no-vulgar.mobi output/cantodict-jyutping-no-vulgar/kindle-cantodict-jyutping-no-vulgar/cantodict.opf
kindlegen -o cantodict-jyutping.mobi output/cantodict-jyutping/kindle-cantodict-jyutping/cantodict.opf

kindlegen -o cantodict-yale-no-incomplete-no-vulgar.mobi output/cantodict-yale-no-incomplete-no-vulgar/kindle-cantodict-yale-no-incomplete-no-vulgar/cantodict.opf
kindlegen -o cantodict-yale-no-incomplete.mobi output/cantodict-yale-no-incomplete/kindle-cantodict-yale-no-incomplete/cantodict.opf
kindlegen -o cantodict-yale-no-vulgar.mobi output/cantodict-yale-no-vulgar/kindle-cantodict-yale-no-vulgar/cantodict.opf
kindlegen -o cantodict-yale.mobi output/cantodict-yale/kindle-cantodict-yale/cantodict.opf

# Move to the right spot
mv output/cantodict-jyutping-no-incomplete-no-vulgar/kindle-cantodict-jyutping-no-incomplete-no-vulgar/cantodict-jyutping-no-incomplete-no-vulgar.mobi output/cantodict-jyutping-no-incomplete-no-vulgar
mv output/cantodict-jyutping-no-incomplete/kindle-cantodict-jyutping-no-incomplete/cantodict-jyutping-no-incomplete.mobi output/cantodict-jyutping-no-incomplete
mv output/cantodict-jyutping-no-vulgar/kindle-cantodict-jyutping-no-vulgar/cantodict-jyutping-no-vulgar.mobi output/cantodict-jyutping-no-vulgar
mv output/cantodict-jyutping/kindle-cantodict-jyutping/cantodict-jyutping.mobi output/cantodict-jyutping

mv output/cantodict-yale-no-incomplete-no-vulgar/kindle-cantodict-yale-no-incomplete-no-vulgar/cantodict-yale-no-incomplete-no-vulgar.mobi output/cantodict-yale-no-incomplete-no-vulgar
mv output/cantodict-yale-no-incomplete/kindle-cantodict-yale-no-incomplete/cantodict-yale-no-incomplete.mobi output/cantodict-yale-no-incomplete
mv output/cantodict-yale-no-vulgar/kindle-cantodict-yale-no-vulgar/cantodict-yale-no-vulgar.mobi output/cantodict-yale-no-vulgar
mv output/cantodict-yale/kindle-cantodict-yale/cantodict-yale.mobi output/cantodict-yale
