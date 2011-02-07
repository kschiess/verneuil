
class Verneuil::Address
  attr_accessor :ip
  
  def initialize(ip, generator)
    @ip = ip
    @generator = generator
  end
  
  def inspect
    "-> #{ip}"
  end
  
  def resolve
    @generator.resolve(self)
  end
  
  def ==(other)
    self.ip == other.ip
  end
end