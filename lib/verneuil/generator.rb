
require 'verneuil/process'

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
    current_adr
  end
  
  # Returns an address that points at the location given by +ip+. 
  #
  def abs_adr(ip)
    Verneuil::Address.new(ip, self)
  end
  
  # Returns an address that points at the current location in the program. 
  #
  def current_adr
    Verneuil::Address.new(program.size, self)
  end
  
  # Resolves an address to the current location. 
  #
  def resolve(adr)
    adr.ip = program.size
  end
    
  # This implements many of the instruction methods that are just one-to-one
  # correspondances between methods on the generator and the instructions in
  # the stream. 
  # 
  # Example: 
  #   generator.foo 1,2,3
  #   # will add [:foo, 1,2,3] to the instruction stream. 
  #
  Verneuil::Process.instance_methods.
    select { |method| method.to_s =~ /^instr_(.*)/ }.
    map { |method| method.to_s[6..-1].to_sym }.each do |instruction|
      define_method(instruction) do |*args|
        add_instruction instruction, *args
      end
    end
end