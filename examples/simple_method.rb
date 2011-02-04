$:.unshift File.dirname(__FILE__) + "/../lib"
require 'verneuil'

code = <<RUBY
def foo(n)
  if n>1
    foo n-1
    p n   # prints 1, 2
  end
end

puts foo(2)
RUBY

class Context
  def initialize
    @vars = {}
  end
  def local_variable_get(name)
    @vars[name]
  end
  def local_variable_set(name, value)
    @vars[name] = value
  end
end

program = Verneuil::Compiler.compile(code)
puts program
puts
process = Verneuil::Process.new(program, Context.new)
p process.run