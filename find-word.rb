#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rubygems'
require 'client'
require 'cmd'
require 'datastore'

cmd = CommandLine.new do
  parameter 'letters', 'the letters you have'
  parameter 'patterns', 'one or more patterns in regex format'
  option 'o', 'online', GetoptLong::NO_ARGUMENT, 'retrieve additional words from the internet'
  example '-o bableso "^..g.*" "^.x..?$"'
end

class Dictionary < DataObject
  set :words
end

$db = Datastore.new('scrabble')
$db['dictionary'] << Dictionary.new if $db['dictionary'].length == 0
$dictionary = $db['dictionary'][0]

letters = cmd.parameters.shift
if cmd.opt 'o'
  client = HttpClient.get "http://www.morewords.com/words-within/#{letters}" do
    body.scan(/<a href="\/word\/(\w+)">/) {|word, w| $dictionary.words << word if word.length <= 8 }
  end
  client = HttpClient.get "http://www.morewords.com/words-within-plus/#{letters}" do
    body.scan(/<a href="\/word\/(\w+)">/) {|word, w| $dictionary.words << word if word.length <= 8 }
  end
end

$db.commit

cmd.parameters.each {|pattern|
  full_letters = letters + pattern.scan(/\w/).join('')
  matches = $dictionary.words.select {|word| word.match(pattern) && word.delete(full_letters).length == 0 }
  matches = matches.to_set.to_a
  puts "#{pattern}: #{matches.sort_by do |m| [m.length, m] end}"
  puts "-" * 80
}

