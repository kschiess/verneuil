
require 'ruby_parser'

# Compiles verneuil code into a program. 
#
class Verneuil::Compiler
  def initialize
    @generator = Verneuil::Generator.new
  end
  
  def program
    @generator.program
  end
  
  def self.compile(*args)
    new.compile(*args)
  end
    
  # Compiles a piece of code within the current program. This means that any
  # method definitions that have already been encountered will be used to 
  # resolve method calls. Returns the program which can also be accessed 
  # using #program on the compiler instance. 
  #
  def compile(code)
    parser = RubyParser.new
    sexp = parser.parse(code)
    # pp sexp
    
    visitor   = Visitor.new(@generator, self)
    visitor.visit(sexp)
    
    @generator.program
  end
  
  # Compiler visitor visits sexps and transforms them into executable code
  # by calling back on its code generator. 
  #
  class Visitor
    NOPOP = [:return, :defn, :class]
    
    def initialize(generator, compiler)
      @generator = generator
      @compiler = compiler
      
      @class_context = []
    end
    
    def visit(sexp)
      type, *args = sexp
      
      sym = "accept_#{type}".to_sym
      
      raise ArgumentError, "No sexp given?" unless sexp && type
      
      raise NotImplementedError, "No acceptor for #{sexp}." \
        unless respond_to? sym

      self.send(sym, *args)
    end
    
    #--------------------------------------------------------- visitor methods
    
    # s(:call, RECEIVER, NAME, ARGUMENTS) - Method calls with or without
    # receiver.
    # 
    def accept_call(receiver, method_name, args)
      argc = visit(args)
      
      if receiver
        visit(receiver)
        @generator.ruby_call method_name, argc
      else
        @generator.ruby_call_implicit method_name, argc
      end
    end
    
    # s(:arglist, ARGUMENT, ARGUMENT) - Argument lists. Needs to return the
    # actual number of arguments that we've compiled. 
    #
    def accept_arglist(*args)
      args.each do |arg|
        visit(arg)
      end
      return args.size
    end

    # s(:block, STATEMENT, STATEMENT, ...) - Blocks of code. 
    #
    def accept_block(*statements)
      statements.each_with_index do |statement, idx|
        type, *rest = statement
        
        visit(statement)
        
        unless idx+1 == statements.size ||
          NOPOP.include?(type)
          @generator.pop 1 
        end
      end
    end

    # s(:lit, LITERAL) - A literal value.
    #
    def accept_lit(value)
      @generator.load value
    end

    # s(:array, ELEMENTS) - array literal. 
    # 
    def accept_array(*elements)
      elements.each { |el| visit(el) }
      @generator.load Array
      @generator.ruby_call :"[]", elements.size
    end

    # s(:if, COND, THEN, ELSE) - an if statement
    #
    def accept_if(cond, _then, _else)
      adr_else = @generator.fwd_adr
      adr_end  = @generator.fwd_adr
      
      visit(cond)
      @generator.jump_if_false adr_else
      
      visit(_then)
      @generator.jump adr_end
      
      adr_else.resolve
      if _else
        visit(_else)
      else
        @generator.load nil
      end
      adr_end.resolve
    end

    # s(:while, test, body, true) - a while statement. 
    #
    def accept_while(cond, body, t)
      fail "What is t for?" unless t

      adr_end = @generator.fwd_adr
    
      adr_test = @generator.current_adr
      visit(cond)
      @generator.jump_if_false adr_end
      
      visit(body)
      @generator.jump adr_test
      
      adr_end.resolve
    end
    
    # s(:op_asgn_or, s(:lvar, :a), s(:lasgn, :a, s(:lit, 1))) - var ||= value.
    #
    def accept_op_asgn_or(variable, assign)
      (*), var, val = assign
      visit(
        s(:lasgn, var, 
          s(:if, 
            s(:defined, variable), 
            variable, 
            val)))
    end
    
    # s(:defined, s(:lvar, :a)) - test if a local variable is defined. 
    #
    def accept_defined(exp)
      type, * = exp
      case type
        when :call
          # s(:call, nil, :a, s(:arglist))
          @generator.test_defined exp[2]
        when :lvar
          # s(:lvar, :a)
          @generator.test_defined exp.last
        when :lit
          @generator.load 'expression'
      else
        fail "Don't know how to implement defined? with #{variable.inspect}."
      end
    end
    
    # s(:lasgn, VARIABLE, VALUE) - assignment of local variables. 
    # s(:lasgn, VARIABLE) - implicit assignment of local vars.
    #
    def accept_lasgn(*args)
      if args.size == 2
        val = args.last
        visit(val)
      end

      name = args.first
      @generator.dup 0
      @generator.lvar_set name
    end
    
    # s(:lvar, VARIABLE) - local variable access.
    #
    def accept_lvar(name)
      visit(
        s(:call, nil, name, s(:arglist)))
    end

    # s(:defn, NAME, ARG_NAMES, BODY) - a method definition.
    #
    def accept_defn(name, args, body)
      # Jumping over functions so that definitions don't get executed.
      adr_end = @generator.fwd_adr
      @generator.jump adr_end
      
      @generator.program.add_method(
        @class_context.last, 
        name, 
        @generator.current_adr)

      # Enters a new local scope and defines arguments
      visit(args)

      visit(body)
      @generator.return
      
      adr_end.resolve
    end

    # s(:class, :Fixnum, SUPER, s(:scope, s(:defn, :foo, s(:args), DEF))) - 
    # a method definition for a class.
    #
    # NOTE that verneuils classes don't work like Rubies classes at all. This
    # is more or less just a method for masking methods on Ruby classes, 
    # not a way to define classes. 
    #
    def accept_class(name, _, scope)
      @class_context.push name
      
      visit(scope)
    ensure
      @class_context.pop
    end
    
    # s(:args, ARGUMENT_NAMES) 
    #
    def accept_args(*arg_names)
      arg_names.each do |name|
        if name.to_s.start_with?('&')
          stripped_name = name.to_s[1..-1].to_sym
          @generator.load_block
          @generator.lvar_set stripped_name
        else
          @generator.lvar_set name
        end
      end
    end
    
    # s(:scope, BODY) - a new scope.
    #
    def accept_scope(body)
      # For now, we don't know what we'll eventually do with scopes. So here
      # is this very basic idea...
      visit(body)
    end
    
    # s(:return, RETVAL) - return from the current method. 
    #
    def accept_return(val)
      visit(val)
      @generator.return 
    end
    
    # s(:iter, s(:call, RECEIVER, METHOD, ARGUMENTS), ASSIGNS, BLOCK) - call
    # a method with a block. 
    #
    def accept_iter(call, assigns, block)
      # Jump over the block code
      adr_end_of_block = @generator.fwd_adr
      @generator.jump adr_end_of_block
      
      adr_start_of_block = @generator.current_adr
      
      if assigns
        type, *names = assigns
        fail "BUG: Unsupported type of block arguments: #{type}" \
          unless type == :lasgn
        accept_args(*names)
      end
      visit(block)
      @generator.return 

      adr_end_of_block.resolve
      
      # Compile the call as we would normally, adding a push_block/pop_block
      # around it. 
      @generator.push_block adr_start_of_block
      visit(call)
      @generator.pop_block
    end

    # true.
    #
    def accept_true
      @generator.load true
    end
    
    # false.
    #
    def accept_false
      @generator.load false
    end
    
    # self
    #
    def accept_self
      @generator.load_self
    end
    
  end
end