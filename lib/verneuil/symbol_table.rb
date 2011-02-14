
# A registry for methods. 
#
class Verneuil::SymbolTable
  attr_reader :methods
  
  def initialize
    @methods = {}
  end
  
  # Defines a function. This function will override the default of calling
  # back to Ruby. 
  #
  # Example: 
  #   # Replaces Foo#bar with the V method at address 15.
  #   add_method(:Foo, :bar, Verneuil::Address.new(15))
  #
  def add(method)
    key = [method.receiver, method.name]
    @methods[key] = method
  end
  
  # Returns the function that matches the given receiver and method name. 
  #
  def lookup_method(recv, name)
    key = if recv
      [recv.class.name.to_sym, name]
    else
      [nil, name]
    end
    
    @methods[key]
  end
end