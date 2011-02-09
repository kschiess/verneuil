
# Processor state of one process. 
#
class Verneuil::Process
  # Create a process, giving it a program to run and a context to run in. 
  #
  def initialize(program, context)
    # p program
    
    # The program that is being executed.
    @program = program
    # Keeps the current scope and the ones before it.
    @scopes  = [scope(context)]
    # Keeps implicit blocks when executing iteration code. 
    @blocks  = []
    # Value stack
    @stack = []
    # Return address stack
    @call_stack = []
    # Instruction pointer
    @ip = 0
    # Should we stop immediately? Cannot restart after setting this. 
    @halted = false
  end
  
  # Runs the program until it completes and returns the last expression
  # in the program.
  #
  def run
    until halted?
      step
    end
    
    @stack.last
  end
  
  # Runs one instruction and returns nil. If this was the last instruction, 
  # it returns the programs return value. 
  #
  def step
    instruction = fetch_and_advance
    dispatch(instruction)
  
    # p [@ip, instruction, @stack, current_scope, @call_stack]
    
    instr_halt if @ip >= @program.size
    
    halted? ? @stack.last : nil
  end
  
  # Override Kernel.fork here so that nobody forks for real without wanting
  # to. 
  def self.fork(*args, &block)
    fail "BUG: Forking inside verneuil code should not call Kernel.fork."
  end
  
  # Returns true if the process has halted because it has reached its end.
  #
  def halted?
    !!@halted
  end
  
  # Fetches the next instruction and advances @ip.
  #
  def fetch_and_advance
    # Pretends that the memory beyond the current space is filled with :halt
    # instructions.
    return :halt if @ip >= @program.size
    
    instruction = @program[@ip]
    @ip += 1
    
    instruction
  end
  
  # Decodes the instruction into opcode and arguments and calls a method
  # on this instance called opcode_OPCODE giving the arguments as method 
  # arguments. 
  #
  def dispatch(instruction)
    opcode, *rest = instruction
    sym = "instr_#{opcode}"

    begin
      self.send(sym, *rest)
    rescue NoMethodError => ex
      # Catch our own method error, but not those that happen inside an 
      # instruction that exists..
      if ex.message.match(/#{sym}/)
        warn @program
        exception "Unknown opcode #{opcode} (missing ##{sym})."
      else
        raise
      end
    end
  end
  
  # Raises an exception that contains useful information about where the 
  # process stopped. 
  #
  def exception(message)
    fail message
  end
  
  # Produces a new scope that links to the given context. 
  #
  def scope(context)
    Verneuil::Scope.new(context)
  end
    
  # Returns the currently active scope. 
  #
  def current_scope
    @scopes.last
  end
  
  # Enters a block. This pushes args to the stack, installs the scope given
  # and jumps to adr. 
  #
  def enter_block(args, adr, scope)
    args.each { |arg| @stack.push arg }
    
    @scopes.push scope
    
    @call_stack.push @ip
    jump adr
  end
  
  # Jumps to the given address. 
  #
  def jump(adr)
    @ip = adr.ip
  end

  # Calls the given address. (like a jump, but puts something on the return
  # stack) If context is left empty, it will call inside the current context.
  #
  def call(adr, context=nil)
    @scopes.push scope(context || current_scope.context)
    @call_stack.push @ip
    jump adr
  end

  # VM Implementation --------------------------------------------------------
  
  # A call to an implicit target (self).
  #
  def instr_ruby_call_implicit(name, argc)
    # Local variable
    if argc==0 && current_scope.lvar_exist?(name)
      @stack.push current_scope.lvar_get(name)
      return
    end
    
    # Verneuil method?
    v_method = @program.lookup_method(nil, name)
    if v_method
      call v_method.address
      return
    end
    
    # Ruby method! (or else)
    args = @stack.pop(argc)
    @stack.push current_scope.method_call(name, *args)
  end
  
  # A call to an explicit receiver. The receiver should be on top of the stack. 
  #
  def instr_ruby_call(name, argc)
    receiver = @stack.pop

    # Verneuil method? (class method mask)
    v_method = @program.lookup_method(
      receiver.class.name.to_sym, 
      name)
    if v_method
      call v_method.address, receiver
      return
    end
    
    # Must be a Ruby method then. The catch allows internal classes like 
    # Verneuil::Block to skip the stack.push.
    args     = @stack.pop(argc)
    catch(:verneuil_code) {
      retval = receiver.send(name, *args)
      @stack.push retval
    }
  end
  
  # ------------------------------------------------------------ STACK CONTROL 
  
  # Pops n elements off the internal stack
  #
  def instr_pop(n)
    @stack.pop(n)
  end
  
  # Loads a literal value to the stack. 
  # 
  def instr_load(val)
    @stack.push val
  end
  
  # Duplicates the value given by stack_idx (from the top) and pushes it 
  # to the stack. 
  #
  def instr_dup(stack_idx)
    @stack.push @stack[-stack_idx-1]
  end
  
  # ----------------------------------------------------------------- JUMPS !!
  
  # Jumps to the given address if the top of the stack contains a false value.
  #
  def instr_jump_if_false(adr)
    val = @stack.pop
    @ip = adr.ip unless val
  end
  
  # Unconditional jump
  #
  def instr_jump(adr)
    jump adr
  end
  
  # Returning from a method (pops the call_stack.)
  # 
  def instr_return
    exception "Nothing to return to on the call stack." if @call_stack.empty?
    @ip = @call_stack.pop
    @scopes.pop
  end
  
  # ---------------------------------------------------------------- VARIABLES

  # Tests if the local variable exists. Puts true/false to the stack. 
  #
  def instr_test_defined(name)
    @stack.push current_scope.defined?(name)
  end

  # Sets the local variable given by name. 
  #
  def instr_lvar_set(name)
    current_scope.lvar_set(name, @stack.pop)
  end
    
  # ------------------------------------------------------------------- BLOCKS 
  
  # Pushes a block context to the block stack. 
  #
  def instr_push_block(block_adr)
    @blocks.push Verneuil::Block.new(
      block_adr, 
      self, 
      current_scope.child)
  end

  # Loads the currently set implicit block to the stack. This is used when
  # turning an implicit block into an explicit block by storing it to a 
  # local variable. 
  #
  def instr_load_block
    fail "BUG: No implicit block!" if @blocks.empty?
    @stack.push @blocks.last
  end
  
  # Unloads a block
  #
  def instr_pop_block
    @blocks.pop
  end

  # Halts the processor and returns the last value on the stack. 
  # 
  def instr_halt
    @halted = true
  end

  # ------------------------------------------------------ METHODS FOR CLASSES 
  
  # Loads the self on the stack. Toplevel self is the context you give, later
  # on this may change to the class we're masking a method of. 
  #
  def instr_load_self
    @stack.push current_scope.context
  end
  
end