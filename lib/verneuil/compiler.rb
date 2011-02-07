
require 'ruby_parser'

# Compiles verneuil code into a program. 
#
class Verneuil::Compiler
  attr_reader :functions
  
  def initialize
    @generator = Verneuil::Generator.new
    @functions = {}
  end
  
  # Defines a function. 
  #
  def add_function(name, args, adr)
    functions[name] = Verneuil::Method.new(name, args, adr)
  end
  
  # Returns the function that matches the given receiver and method name. 
  #
  def lookup_function(recv, name)
    functions[name]
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
    NOPOP = [:return, :defn]
    
    def initialize(generator, compiler)
      @generator = generator
      @compiler = compiler
    end
    
    def visit(sexp)
      type, *args = sexp
      
      sym = "accept_#{type}".to_sym
      
      unless respond_to? sym
        raise NotImplementedError, "No acceptor for #{sexp}"
      end

      self.send(sym, *args)
    end
    
    # s(:call, RECEIVER, NAME, ARGUMENTS) - Method calls with or without
    # receiver.
    # 
    def accept_call(receiver, method_name, args)
      argc = visit(args)
      
      # Method resolution: 
      # Tries V-methods first, followed by fallback on Ruby methods (sent 
      # to the context if no receiver was given).

      method = @compiler.lookup_function(receiver, method_name)
      if method
        @generator.call method.address
      else
        if receiver
          visit(receiver)
          @generator.ruby_call method_name, argc
        else
          argc = visit(args)
          @generator.ruby_call_implicit method_name, argc
        end
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

    # s(:if, COND, THEN, ELSE) - an if statement
    #
    def accept_if(cond, _then, _else)
      adr_else = @generator.fwd_adr
      adr_end  = @generator.fwd_adr
      
      visit(cond)
      @generator.jump_if_false adr_else
      
      visit(_then)
      @generator.jump adr_end
      
      @generator.resolve(adr_else)
      if _else
        visit(_else)
      else
        @generator.load nil
      end
      @generator.resolve(adr_end)
    end

    # s(:lasgn, VARIABLE, VALUE) - assignment of local variables. 
    #
    def accept_lasgn(name, val)
      visit(val)
      @generator.dup 1
      @generator.lvar_set name
    end
    
    # s(:lvar, VARIABLE) - local variable access.
    #
    def accept_lvar(name)
      @generator.lvar_get name
    end

    # s(:defn, NAME, ARG_NAMES, BODY) - a method definition.
    #
    def accept_defn(name, args, body)
      # Jumping over functions so that definitions don't get executed.
      adr_end = @generator.fwd_adr
      @generator.jump adr_end
      
      @compiler.add_function(name, args, @generator.current_adr)

      # Enters a new local scope and defines arguments
      @generator.enter
      visit(args)

      visit(body)
      @generator.return
      
      @generator.resolve adr_end
    end
    
    # s(:args, ARGUMENT_NAMES) 
    #
    def accept_args(*arg_names)
      arg_names.each do |name|
        @generator.lvar_set name
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

    def accept_true
      @generator.load true
    end
    def accept_false
      @generator.load false
    end
  end
end