#!/bin/bash

# Generate all the yale dictionaries.
bundle exec ruby make-dict.rb
bundle exec ruby make-dict.rb -c
bundle exec ruby make-dict.rb -n
bundle exec ruby make-dict.rb -c -n

# Generate all the jyutping dictionaries.
bundle exec ruby make-dict.rb -j
bundle exec ruby make-dict.rb -j -c
bundle exec ruby make-dict.rb -j -n
bundle exec ruby make-dict.rb -j -c -n

# dictgen binary from https://pgaskin.net/dictutil/dictgen/

dictgen-darwin-64bit -o output/cantodict-jyutping-no-incomplete-no-vulgar/dicthtml-zh_HK.zip output/cantodict-jyutping-no-incomplete-no-vulgar/kobo-cantodict-jyutping-no-incomplete-no-vulgar.df
dictgen-darwin-64bit -o output/cantodict-jyutping-no-incomplete/dicthtml-zh_HK.zip output/cantodict-jyutping-no-incomplete/kobo-cantodict-jyutping-no-incomplete.df
dictgen-darwin-64bit -o output/cantodict-jyutping-no-vulgar/dicthtml-zh_HK.zip output/cantodict-jyutping-no-vulgar/kobo-cantodict-jyutping-no-vulgar.df
dictgen-darwin-64bit -o output/cantodict-jyutping/dicthtml-zh_HK.zip output/cantodict-jyutping/kobo-cantodict-jyutping.df
dictgen-darwin-64bit -o output/cantodict-yale-no-incomplete-no-vulgar/dicthtml-zh_HK.zip output/cantodict-yale-no-incomplete-no-vulgar/kobo-cantodict-yale-no-incomplete-no-vulgar.df
dictgen-darwin-64bit -o output/cantodict-yale-no-incomplete/dicthtml-zh_HK.zip output/cantodict-yale-no-incomplete/kobo-cantodict-yale-no-incomplete.df
dictgen-darwin-64bit -o output/cantodict-yale-no-vulgar/dicthtml-zh_HK.zip output/cantodict-yale-no-vulgar/kobo-cantodict-yale-no-vulgar.df
dictgen-darwin-64bit -o output/cantodict-yale/dicthtml-zh_HK.zip output/cantodict-yale/kobo-cantodict-yale.df
