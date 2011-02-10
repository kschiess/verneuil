
require 'verneuil/instruction'

# A program is a sequence of instructions that can be run inside a process.
# You can use the compiler (Verneuil::Compiler) to create programs.
#
class Verneuil::Program
  # Gives access to the internal array of instructions (the program memory)
  attr_reader :instructions
  
  def initialize
    @instructions = []
    @functions = {}
  end
    
  # Make programs behave nicely with respect to comparison. 
  def hash # :nodoc: 
    instructions.hash
  end
  def eql?(program) # :nodoc: 
    instructions.eql? program.instructions
  end
  def ==(program)
    instructions == program.instructions
  end
  
  # Retrieves instruction at idx
  # 
  def [](idx)
    instructions[idx]
  end
  
  # Returns the size of the current program
  #
  def size
    instructions.size
  end
    
  # Adds an instruction to the program. (at the end)
  #
  def add(instruction)
    @instructions << instruction
  end
  
  # Defines a function. 
  #
  def add_method(klass, name, adr)
    @functions[[klass, name]] = Verneuil::Method.new(klass, name, adr)
  end
  
  # Returns the function that matches the given receiver and method name. 
  #
  def lookup_method(recv, name)
    key = if recv
      [recv.class.name.to_sym, name]
    else
      [nil, name]
    end
    
    @functions[key]
  end
  
  # Printing
  # 
  def inspect
    s = ''
    @instructions.each_with_index do |instruction, idx|
      method_label = ''
      if entry=@functions.find { |(r,n), m| m.address.ip == idx }
        m = entry.last
        method_label = [m.receiver, m.name].inspect
      end
      s << sprintf("%20s %04d %s\n", method_label, idx, instruction)
    end
    s
  end
end