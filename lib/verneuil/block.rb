
# Abstracts the notion of a block.
#
class Verneuil::Block
  def initialize(adr, process, scope)
    @adr      = adr
    @process  = process
    @scope    = scope
  end
  
  def call(*args)
    @process.install_scope(@scope) 
    @process.instr_call(@adr)
  end
  
  def inspect
    "block@#{@adr.ip}(#{@scope.inspect})"
  end
end