$:.unshift File.dirname(__FILE__) + "/../lib"
require 'verneuil'

code    = "puts 42"
program = Verneuil::Compiler.compile(code)
process = Verneuil::Process.new(program, self)
process.run   # prints 42 to the console.
