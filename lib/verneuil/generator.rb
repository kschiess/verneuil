
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
  
  # Returns an address that hasn't been fixed to an instruction pointer yet. 
  # 
  def fwd_adr
    Verneuil::Address.new
  end
  
  # Returns an address that points at the location given by +ip+. 
  #
  def abs_adr(ip)
    Verneuil::Address.new(ip)
  end
  
  # Resolves an address to the current location. 
  #
  def resolve(adr)
    adr.ip = program.size
  end
  
  # Override built in dup. 
  #
  def dup(n)
    add_instruction :dup, n
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