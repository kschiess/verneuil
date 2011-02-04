
# Processor state of one process. 
#
class Verneuil::Process
  # Create a process, giving it a program to run and a context to run in. 
  #
  def initialize(program, context)
    @context, @program = context, program
    
    @ip = 0
    @stack = []
    @call_stack = []
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
  
    p [@ip, instruction, @stack, @call_stack]
    
    instr_halt if @ip >= @program.size
    
    halted? ? @stack.last : nil
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
  
  # VM Implementation --------------------------------------------------------
  
  # A call to an implicit target, in this case the context. 
  #
  def instr_ruby_call_implicit(name, argc)
    args = @stack.pop(argc)
    @stack.push @context.send(name, *args)
  end
  
  # A call to an explicit receiver. The receiver should be on top of the stack. 
  #
  def instr_ruby_call(name, argc)
    receiver = @stack.pop
    args     = @stack.pop(argc)

    @stack.push receiver.send(name, *args)
  end
  
  
  # Pops n elements off the internal stack
  #
  def instr_pop(n)
    @stack.pop(n)
  end
  
  # Rolls the stack contents starting at idx forward. 
  #
  # Example: 
  #   ..., 3, 4, 5 becomes
  #   ..., 5, 3, 4 
  #   upon roll 2
  #
  def instr_roll(n)
    i = -(n+1)
    @stack[i..-1] = [@stack[-1], @stack[i..-2]].flatten
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
  
  # Halts the processor and returns the last value on the stack. 
  # 
  def instr_halt
    @halted = true
  end

  # JUMPS !!
  
  # Jumps to the given address if the top of the stack contains a false value.
  #
  def instr_jump_if_false(adr)
    val = @stack.pop
    @ip = adr.ip unless val
  end
  
  # Unconditional jump
  #
  def instr_jump(adr)
    @ip = adr.ip
  end
  
  # Calling verneuil-methods.
  #
  def instr_call(adr)
    @call_stack.push @ip
    @ip = adr.ip
  end
  
  # Returning from a method (pops the call_stack.)
  # 
  def instr_return
    exception "Nothing to return to on the call stack." if @call_stack.empty?
    @ip = @call_stack.pop
  end
end