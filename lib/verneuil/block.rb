
# Abstracts the notion of a block.
#
class Verneuil::Block
  # At what address does the block code start?
  attr_reader :address
  attr_reader :scope
  
  def initialize(address, process, scope)
    @address  = address
    @process  = process
    @scope    = scope
  end
  
  def call(*args)
    @process.enter_block(args, @address, @scope)
    throw :verneuil_code
  end
  
  def inspect
    "block@#{@address.ip}(#{@scope.inspect})"
  end
end