
class Verneuil::Address < Struct.new(:ip)
  def inspect
    "-> #{ip}"
  end
end