
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
    args.each do |arg|
      @process.instance_variable_get('@stack').push arg
    end
    @process.instr_call(@adr)
  end
  
  def inspect
    "block@#{@adr.ip}(#{@scope.inspect})"
  end
end