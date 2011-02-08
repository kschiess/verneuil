
# Abstracts the notion of a block.
#
class Verneuil::Block
  def initialize(adr, process, scope)
    @adr      = adr
    @process  = process
    @scope    = scope
  end
  
  def call(*args)
    @process.enter_block(args, @adr, @scope)
    throw :verneuil_code
  end
  
  def inspect
    "block@#{@adr.ip}(#{@scope.inspect})"
  end
end