
# The execution scope for verneuil code. This maintains a link to the external
# context given when starting the process to be able to delegate method calls
# to user code. 
#
class Verneuil::Scope
  # In Ruby, we also call this the 'self'.
  attr_reader :context
  
  def initialize(context, local_vars={}, parent=nil)
    @local_vars = local_vars
    @context = context
    @parent = parent
  end
  
  def lvar_exist?(name)
    lvar_exist_locally?(name) || @parent && @parent.lvar_exist?(name)
  end
  def lvar_exist_locally?(name)
    @local_vars.has_key?(name)
  end
  def lvar_get(name)
    unless lvar_exist_locally? name
      return @parent.lvar_get(name) if @parent
      
      raise Verneuil::NameError, "No such local variable #{name.inspect}."
    end

    @local_vars[name]
  end
  def lvar_set(name, value)
    unless lvar_exist_locally? name
      return @parent.lvar_set(name, value) if @parent && @parent.lvar_exist?(name)
    end

    @local_vars[name] = value
  end
  def defined?(name)
    return 'local-variable' if lvar_exist?(name)
    return 'method' if context.respond_to?(name)
    nil
  end

  # Returns a nested scope that has access to the current scope in a Ruby 1.9
  # fashion. 
  #
  def child(local_vars={})
    self.class.new(context, local_vars, self)
  end

  def method_call(name, *args)
    context.send(name, *args)
  end
  
  def inspect
    "scope(#{@local_vars.inspect[2..-2]})" + 
      (@parent ? "-> #{@parent.inspect}" : '')
  end
end