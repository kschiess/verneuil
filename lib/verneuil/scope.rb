
# The execution scope for verneuil code. This maintains a link to the external
# context given when starting the process to be able to delegate method calls
# to user code. 
#
class Verneuil::Scope
  attr_reader :context
  
  def initialize(context, local_vars={}, parent=nil)
    @local_vars = local_vars
    @context = context
    @parent = parent
  end
  
  def enter
    Verneuil::Scope.new(context, {}, self)
  end
  def leave
    return self unless @parent
    @parent
  end
  
  def lvar_get(name)
    raise Verneuil::NameError, "No such local variable #{name.inspect}." \
      unless @local_vars.has_key?(name)
    @local_vars[name]
  end
  def lvar_set(name, value)
    @local_vars[name] = value
  end

  def method_call(name, *args)
    context.send(name, *args)
  end
  
  def inspect
    "scope(#{@local_vars.inspect[2..-2]})" + 
      (@parent ? "-> #{@parent.inspect}" : '')
  end
end