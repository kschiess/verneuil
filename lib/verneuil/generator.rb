
# A generator for VM code. 
#
class Verneuil::Generator
  # Returns the instruction stream as has been assembled to this moment. 
  #
  attr_reader :program
  
  def initialize
    @program = Verneuil::Program.new
  end
  
  # Adds an instruction to the current stream.
  #
  def add_instruction(*parts)
    @program.add Verneuil::Instruction.new(*parts)
  end
  
  # This implements many of the instruction methods that are just one-to-one
  # correspondances between methods on the generator and the instructions in
  # the stream. 
  # 
  # Example: 
  #   generator.foo 1,2,3
  #   # will add [:foo, 1,2,3] to the instruction stream. 
  #
  def method_missing(sym, *args, &block)
    super if block
    
    add_instruction sym, *args
  end
end