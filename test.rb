require 'ruby_parser'
require 'pp'
pp RubyParser.new.parse('
  test while foo
')
