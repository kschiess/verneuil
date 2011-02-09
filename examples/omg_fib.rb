$:.unshift File.dirname(__FILE__) + "/../lib"
require 'verneuil'

code = <<RUBY
def fib(n)
  return n if (0..1).include? n
  fib(n-1) + fib(n-2) if n > 1
end

puts fib(10)
RUBY

program = Verneuil::Compiler.compile(code)
puts program.inspect
puts
process = Verneuil::Process.new(program, nil)
process.run