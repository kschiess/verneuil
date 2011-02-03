
# Processor state of one process. 
#
class Verneuil::Process
  # Create a process, giving it a program to run and a context to run in. 
  #
  def initialize(program, context)
    @context, @program = context, program
    
    @ip = 0
    @stack = []
  end
  
  def run
    catch(:halt) {
      loop do
        instruction = fetch_and_advance
        return unless instruction

        dispatch(instruction)
      end
    }
    return @stack.last
  end
  
  # Fetches the next instruction and advances @ip.
  #
  def fetch_and_advance
    throw :halt if @ip >= @program.size
    
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
    rescue NoMethodError
      exception "Unknown opcode #{opcode} (missing ##{sym})."
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
  
end