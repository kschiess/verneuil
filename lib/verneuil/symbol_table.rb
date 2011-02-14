
# A registry for methods. 
#
class Verneuil::SymbolTable
  attr_reader :methods
  
  def initialize
    @methods = {}
  end
  
  # Defines a function. This function will override the default of calling
  # back to Ruby. Methods added here must support at least #receiver, 
  # #name and #invoke. 
  #
  # Example: 
  #   # Replaces Foo#bar with the V method at address 15.
  #   add(method_obj)
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