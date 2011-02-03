
# A single instruction for the verneuil processor. This is like sexp a thin
# wrapper around array.
#
class Verneuil::Instruction < Array
  def initialize(*parts)
    super(parts.size)
    replace(parts)
  end
end