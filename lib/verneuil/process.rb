
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
    # This process' children
    @children = []
    # The list of processes that this process waits for currently. 
    @joining = []
  end

  # Instruction pointer
  attr_accessor :ip
  
  # A process is also a process group, containing its children. 
  attr_reader :children
  
  # The list of processes that this process waits for currently. 
  attr_reader :joining
  
  # Runs the program until it completes and returns the last expression
  # in the program.
  #
  def run
    until halted?
      step
    end
    
    @stack.last
  end
  
  # Runs one instruction. If the current process waits on another process
  # (joining not empty), it will run an instruction in the other process
  # instead.
  #
  def step
    verify_wait_conditions
    
    if waiting?
      joining.first.step
      return 
    end
    
    instruction = fetch_and_advance
    dispatch(instruction)
  
    # p [self, instruction, @stack, @call_stack, current_scope]
    
    instr_halt if !waiting? && !instruction_pointer_valid?
  end
  
  # Returns true if the process has halted because it has reached its end.
  #
  def halted?
    !!@halted
  end

  # Returns true if the process waits for something to happen.
  #
  def waiting?
    not @joining.empty?
  end
  
  # Once the process has halted?, this returns the top of the stack. This is 
  # like the return value of the process. 
  #
  def value
    @stack.last
  end
  
  # Internal helper methods --------------------------------------------------
  
  def verify_wait_conditions
    @joining.delete_if { |process| process.halted? }
  end
  
  # Returns the process group having this process as root node. 
  #
  def group
    @group ||= Verneuil::ProcessGroup.new(self)
  end
  
  # Fetches the next instruction and advances @ip.
  #
  def fetch_and_advance
    # Pretends that the memory beyond the current space is filled with :halt
    # instructions.
    return :halt unless instruction_pointer_valid?
    
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
    
  # Looks up a method in internal tables. 
  #
  def lookup_method(receiver, name)
    [
      @program.symbols, 
      self.class.symbols
    ].each do |table|
      method = table.lookup_method(receiver, name)
      return method if method
    end
    return nil
  end

  # # Returns a number of arguments from the value stack. Use this to implement
  # # kernel methods written in Ruby that manipulate the V machine. 
  # #
  # def get_args(n)
  #   @stack.pop(n)
  # end
  
  # Returns the currently active block or nil if no such block is available. 
  #
  def current_block
    @blocks.last
  end
  
  # Forks a new process that starts its execution at address and that halts 
  # when encountering a 'return' instruction. Returns that new process 
  # instance. 
  #
  def fork_child(block)
    child = Verneuil::Process.new(@program, nil)
    child.run_block(block)
    
    @children << child
    
    return child
  end
  
  # Confines execution to a single method. This means setting up the return
  # stack to return into nirvana once the VM reaches a 'return' instruction. 
  #
  def run_block(block)
    @call_stack.push(-1)
    jump block.address

    @scopes = [block.scope]
  end
  
  # Pushes a return value to the value stack. 
  #
  def push(value)
    @stack.push value
  end
  
  # True if the current instruction pointer is valid. 
  #
  def instruction_pointer_valid?
    @ip >= 0 && 
      @ip < @program.size
  end

  # Inspection of processes
  #
  def inspect
    "process(#{object_id}, #{@ip}, #{@call_stack}, w:#{@joining.size}, c:#{children.size}, h:#{halted?})"
  end

  def dispatch_to_verneuil(receiver, name)
    if v_method = lookup_method(receiver, name)
      catch(:verneuil_code) {
        retval = v_method.invoke(self, receiver)
        @stack.push retval
      } 
      return true
    end
    
    return false
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
    return if dispatch_to_verneuil(nil, name)
    
    # Ruby method! (or else)
    args = @stack.pop(argc)
    @stack.push current_scope.method_call(name, *args)
  end
  
  # A call to an explicit receiver. The receiver should be on top of the stack. 
  #
  def instr_ruby_call(name, argc)
    receiver = @stack.pop
    
    # TODO Fix argument count handling
    # Currently the caller decides with how many arguments he calls the
    # block and the callee pops off the stack what he wants. This is not a
    # good situation.

    # Verneuil method? (class method mask)
    return if dispatch_to_verneuil(receiver, name)
    
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
    @stack.push current_block
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

require 'verneuil/process/kernel_methods'

require 'verneuil/kernel/fork'
require 'verneuil/kernel/process_join'
