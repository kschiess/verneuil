
require 'verneuil/instruction'

# A program is a sequence of instructions that can be run inside a process.
# You can use the compiler (Verneuil::Compiler) to create programs.
#
class Verneuil::Program
  # Gives access to the internal array of instructions (the program memory)
  attr_reader :instructions
  
  def initialize
    @instructions = []
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
end