
# Processor state of one process. 
#
class Verneuil::Process
  # Create a process, giving it a program to run and a context to run in. 
  #
  def initialize(program, context)
    @context, @program = context, program
    
    @ip = 0
    @stack = []
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
      if ex.message.match(/sym/)
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
  def instr_implicit_call(name, argc)
    args = @stack.pop(argc)
    @stack.push @context.send(name, *args)
  end
  
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
  
  # Halts the processor and returns the last value on the stack. 
  # 
  def instr_halt
    @halted = true
  end
end