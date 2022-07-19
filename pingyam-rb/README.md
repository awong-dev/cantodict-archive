# pingyam-rb - Cantonese romanization conversion in Ruby

This repository contains a Ruby library and example conversion tool that makes use of the open-licensed [Pingyam Database](https://github.com/kfcd/pingyam) to convert between 11 different Cantonese romanization systems and variants.

* [1 Features](#features)
* [2 Included romanization systems](#included-romanization-systems)
* [3 Requirements](#requirements)
* [4 Usage](#usage)
  * [4.1 lib_pingyam](#lib_pingyam)
    * [4.1.1 converting syllables](#converting-syllables)
  * [4.2 convert_pingyam](#convert_pingyam)
    * [4.2.1 Basic usage](#basic-usage)
    * [4.2.2 Checking input validity](#checking-input-validity)
    * [4.2.3 Modifying the output](#modifying-the-output)
    * [4.2.4 Options](#options)
* [5 To do](#to-do)
* [6 See also](#see-also)
* [7 License](#license)

## Features

* Converts to and from any Cantonese romanization scheme (including IPA)
* Can convert single and multiple words / whole lines of romanized text
* Handles mixed input (non-Cantonese text is ignored)
* Converter script ready to use on the command-line -- or include the library in your own code

## Included romanization systems

In total 11 Cantonese romanization systems are available for conversion using this library. Each variant is identified by a number (`0-10`); this number is also used for identifying the "to" and "from" romanizations to use while converting text.

Index | Name | Chinese | Variant
----- | ---- | ------- | -------
`0` | [Yale](https://en.wikipedia.org/wiki/Yale_romanization_of_Cantonese) | 耶魯拼音 | Tone numbers
`1` | Yale | | Tone diacritics
`2` | [Cantonese Pinyin](https://en.wikipedia.org/wiki/Cantonese_Pinyin) | 教院拼音
`3` | [S.L. Wong](https://en.wikipedia.org/wiki/S._L._Wong_(romanisation)) | 黃錫凌 | Tone numbers
`4` | S.L. Wong | | Tone diacritics
`5` | [International Phonetic Alphabet](https://en.wikipedia.org/wiki/International_Phonetic_Alphabet) | 國際音標
`6` | [Jyutping](https://en.wikipedia.org/wiki/Jyutping) | 粵拼
`7` | [Canton](https://en.wikipedia.org/wiki/Guangdong_Romanization#Cantonese) | 廣州拼音
`8` | [Sidney Lau](https://en.wikipedia.org/wiki/Sidney_Lau_romanisation) | 劉錫祥
`9` | [Penkyamp](http://cantonese.wikia.com/wiki/Penkyamp) | 粵語拼音字 | Tone numbers
`10` | Penkyamp | | Tone diacritics

Note: A modified 9-tone Yale system is used by default. However, this library includes a method to convert the Yale transcription to the more traditional 6-tone system (see [below](#modifying-the-output) for details).

## Requirements

This library makes use of the latest version of the [Pingyam database](https://github.com/kfcd/pingyam), and expects a file called `pingyambiu` containing the conversion data to be located in a `pingyam` folder in the project root directory. There a number of ways to do this:

* _Easiest method_: Run the `update_database.rb` script to get the latest version of the script
  * Instructions: In the project root directory, enter the following command: `./update_database.rb`
  * If the current version of the database is different than the one on your machine, your local copy will be updated
* Download the file directly from the Pingyam project [here](https://github.com/kfcd/pingyam/blob/master/pingyambiu).
  * Make sure to create a directory called `pingyam` in the project root and copy the file to that directory
* If you have `git` installed, you can clone the database into the root project folder using the following command: `git clone https://github.com/kfcd/pingyam.git
* Download the Pingyam project into a separate location and create a symlink in the current project directory

There are no other special requirements other than a working version of Ruby.

## Usage

This project can be used either as a library (`lib_pingyam.rb`) or as a command-line script (`convert_pingyam.rb`). Details for both types of usage can be found below.

### lib_pingyam

To use the library, make sure to `require` the library file, e.g.:

```ruby
require_relative 'lib_pingyam.rb'
```

Before you can convert text, you need to initialize a `Converter` object:

```ruby
conv = Converter.new
```

By default, this initializes a conversion dictionary that works from Yale to any other romanization system.

To use a different source romanization system, just specify the corresponding index number as an argument when initializing the `Converter` object, e.g.:

```ruby
conv = Converter.new(6)
# => This converts from Jyutping to any other system
```

You can then convert any string of text using the `convert_line` method, which takes a string and an integer representing the target romanization system as arguments:

```ruby
pingyam = "Yale to Jyutping conversion: yut9 yu5 jyun2 wun6"
puts conv.convert_line(pingyam, 6)
# => Yale to Jyutping conversion: jyut6 jyu5 zyun2 wun6
```

Tip: If you provide `11` as the index number when converting, the string will be translated into all of the available systems sequentially, e.g.:

```ruby
pingyam = "yut9 yu5 ping3 yam1 fong1 on3 yat7 laam4"
puts conv.convert_line(pingyam, 11)
# => yut9 yu5 ping3 yam1 fong1 on3 yat7 laam4 
# => yuht yúh ping yām fōng on yāt làahm 
# => jyt9 jy5 ping3 jam1 fong1 on3 jat7 laam4 
# => jyt⁹ jy⁵ pɪŋ³ jɐm¹ fɔŋ¹ ɔn³ jɐt⁷ lam⁴ 
# => _jyt ˏjy ¯pɪŋ 'jɐm 'fɔŋ ¯ɔn 'jɐt ˌlam 
# => jyːt˨ jyː˩˧ pʰɪŋ˧ jɐm˥ fɔːŋ˥ ɔːn˧ jɐt˥ laːm˨˩ 
# => jyut6 jyu5 ping3 jam1 fong1 on3 jat1 laam4 
# => yud6 yu5 ping3 yem1 fong1 on3 yed1 lam4 
# => yuet⁶ yue⁵ ping³ yam¹ fong¹ on³ yat¹ laam⁴ 
# => yeud6 yeu5 penk3 yamp1 fong1 on3 yat1 lam4 
# => yeùd yeú pênk yämp föng ôn yät lam
```

The `Converter` class has a built-in method for checking if a given string is a valid syllable in any of the available Cantonese romanization systems:

```ruby
conv = Converter.new
# checks against syllables in Yale (numerals) by default

word = "heung1"
puts conv.check_syllable(word)
# => true

word = "heungg1"
puts conv.check_syllable(word)
# => false
```

To check syllables in any other romanization system, just specify it when initializing the `Converter` class:

```ruby
conv = Converter.new(6)
# checks valid Jyutping syllables

word = "heung1"
puts conv.check_syllable(word)
# => false

word = "hoeng1"
puts conv.check_syllable(word)
# => true
```

#### converting syllables

You can convert individual syllables using the `convert_syllable` method of the `Converter` class. This method requires two arguments: a string consisting of a single romanized syllable and an integer representing the index number of the target romanization system.

For example, to convert a syllable in Yale into IPA:

```ruby
conv = Converter.new
p conv.convert_syllable("heung1", 5)
# => "hœːŋ˥"
```

To convert from a different source transcription system, just provide the corresponding index number when initializing the Converter object.

For example, to convert Jyutping into IPA:

```ruby
@conv = Converter.new(6)
p @conv.convert_syllable("hoeng1", 5)
# => "hœːŋ˥"
```

If `11` is passed as the final argument to the `convert_syllable` method, it will return an array containing all of the possible transcriptions of the given syllable:

```ruby
conv = Converter.new
p conv.convert_syllable("heung1", 11)
# => ["heung1", "heūng", "hoeng1", "hœŋ¹", "'hœŋ", "hœːŋ˥", "hoeng1", "hêng1", "heung¹", "heong1", "heöng"]
```

### convert_pingyam

The `convert_pingyam.rb` file found in the root directory is a simple script that demonstrates the use of the `lib_pingyam` library. It allows for quick and easy conversion between arbitrary Cantonese romanization systems on the command-line.

#### Basic usage

```bash
./convert_pingyam.rb -i "This is a test: Yut9 yu5 ping3 yam1 jyun2 wun6"
# => This is a test: yuht yúh ping yām jyún wuhn
```

The above example converts the Cantonese romanization in the provided sentence from Yale (with numerals) into Yale with diacritics. All of the text that is not recognizable as Cantonese romanization (e.g., all of the English text before the colon in the provided sentence) is ignored.

To convert the text into Jyutping instead, just provide the index number for Jyutping (i.e., `6` -- see [list above](#included-romanization-systems)) using the `-t` (`--target`) option:

```bash
./convert_pingyam.rb -i "This is a test: Yut9 yu5 ping3 yam1 jyun2 wun6" -t 6
# => This is a test: jyut6 jyu5 ping3 jam1 zyun2 wun6
```

As can be seen, the text has now been converted into Jyutping romanization. Conversion into other systems is equally easy -- just replace `6` above with the index number of the system you wish to use for output.

To convert from a different source romanization system (e.g., to convert from Jyutping to Yale, or from S.L. Wong to Jyutping), provide the source system index number as a parameter using the `-s` (`--source`) option. The example below converts from Jyutping to Yale with diacritics:

```bash
./convert_pingyam.rb -i "This is a test: jyut6 jyu5 ping3 jam1 zyun2 wun6" -s 6 -t 1
# => This is a test: yuht yúh ping yām jyún wuhn
```

#### Checking input validity

Invalid romanization syllables can be identified using the `-c` (`--check`) option. This checks each word in the input string and outputs a list of words that are not recognizable as valid Cantonese syllables in the given romanization system:

```bash
./convert_pingyam.rb -i "This is a test: Yut9 yu5 ping3 yam1 jyun2 wun6" -c
# => This
# => is
# => a
# => test:
```

The output in the above example contains words that are not valid syllables in Yale romanization (the default, since no other system was specified). To use a different romanization system just provide the appropriate index number using the `-s` option. For example, the command below checks for invalid syllables in Jyutping:

```bash
./convert_pingyam.rb -i "This is a test: Yut9 yu5 ping3 yam1 jyun2 wun6" -c -s 6
# => This
# => is
# => a
# => test:
# => Yut9
# => yu5
# => yam1
```

In the example above, the output contains apart from English the Yale syllables `Yut9`, `yu5`, and `yam1`, because these are not valid syllables in Jyutping.

#### Modifying the output

The output transcription can be further modified using optional command-line flags, for example to convert regular tone numerals to superscript numerals (Unicode), or to revert to the traditional 6-tone Yale system.

* **Superscript numerals**: Several romanization systems use numerals to indicate tones in Cantonese. These are often represented in superscript form to increase readability of romanized text. To use superscript numerals, use the `-S` (`--superscript`) option with any numeral-using transcription system. For example, this will convert `siu2 chak7 si3` to `siu² chak⁷ si³`.
* **Yale normalization**: To use the older 6-tone Yale transcription instead of the default 9-tone modified version, use the `-Y` (`--yale`) option. For example, this will convert `yat7 jek8 kek9` to `yat1 jek3 kek6`.

These modifications can be combined -- the example below both normalizes the Yale transcription and converts the numerals to superscript:

```bash
./convert_pingyam.rb -i "yat7 jek8 kek9" -t 0 -YS
# => yat¹ jek³ kek⁶
```

#### Options

The following options can be provided to `convert_pingyam.rb` to control the conversion process:

* `-c`, `--check`: _Check if input contains invalid Cantonese romanization_
* `-i`, `--input STRING`: _Input string to be converted_
* `-f`, `--filename FILE`: _Provide file for conversion_
* `-s`, `--source INDEX`: _Provide index number of romanization to convert from_
* `-S`, `--superscript`: _Print tone numerals as superscript_
* `-t`, `--target INDEX`: _Provide index number of romanization to convert into_
* `-Y`, `--yale`: _Normalize Yale to 6-tone traditional system_

## To do

* ~~Support for traditional 6-tone Yale (with numerals)~~
* ~~Conversion of tone numbers to superscript~~
* Optional HTML output
* Handle ~~files and~~ pipes as input

## See also

* [Pingyam database](https://github.com/kfcd/pingyam)
* [pingyam-js](https://github.com/dohliam/pingyam-js) - Online Cantonese Romanization Converter
* [pinyin-rb](https://github.com/dohliam/pinyin-rb) - Mandarin Chinese transcription conversion in Ruby

## License

* Romanization data: [CC BY](https://github.com/kfcd/pingyam/blob/master/LICENSE)
* All other code: [MIT](LICENSE)
