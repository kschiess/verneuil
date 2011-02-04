$:.unshift File.dirname(__FILE__) + "/../lib"
require 'verneuil'

code = <<RUBY
def fib(n)
  return n if (0..1).include? n
  fib(n-1) + fib(n-2) if n > 1
end

puts fib(2)
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
process.run