class Verneuil::Process
  # A kernel method points to a Ruby method somewhere.
  #
  class KernelMethod < Struct.new(:receiver, :name, :method)
    def invoke(process, receiver)
      method.call(process, receiver)
    end
  end
  
  # Extends the Process' class with methods that allow managing kernel methods. 
  #
  class <<self
    # The VMs own kernel method table. 
    # 
    def symbols
      @symbols ||= Verneuil::SymbolTable.new
    end
    
    # Registers a kernel method. These methods have precedence over the 
    # Ruby bridge, but can still be overridden by user methods. 
    #
    def kernel_method(klass_name, method_name, &method_definition)
      symbols.add(
        KernelMethod.new(
          klass_name, 
          method_name, 
          method_definition))
    end
  end
end