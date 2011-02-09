$:.unshift File.dirname(__FILE__) + "/../lib"
require 'verneuil'

code = <<RUBY
def foo(n)
  if n>=1
    foo n-1
    p n   # prints 1, 2
  end
end

foo(2)
RUBY

program = Verneuil::Compiler.compile(code)
puts program.inspect
puts
process = Verneuil::Process.new(program, nil)
process.run