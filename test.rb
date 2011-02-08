require 'ruby_parser'
p RubyParser.new.parse('
  def a; end
  defined?(a)
')
