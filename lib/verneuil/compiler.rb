
require 'ruby_parser'

# Compiles verneuil code into a program. 
#
class Verneuil::Compiler
  class Visitor
    def initialize(generator)
      @generator = generator
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
      if receiver
        argc = visit(args)
        visit(receiver)
        @generator.call method_name, argc
      else
        argc = visit(args)
        @generator.implicit_call method_name, argc
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
        visit(statement)
        @generator.pop 1 unless idx+1 == statements.size
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
      @generator.load name
      @generator.dup 1
      @generator.implicit_call :local_variable_set, 2
    end
    
    # s(:lvar, VARIABLE) - local variable access.
    #
    def accept_lvar(name)
      @generator.load name
      @generator.implicit_call :local_variable_get, 1
    end

    def accept_true
      @generator.load true
    end
    def accept_false
      @generator.load false
    end
  end
  
  def compile(code)
    parser = RubyParser.new
    sexp = parser.parse(code)
    # p sexp
    
    generator = Verneuil::Generator.new
    visitor   = Visitor.new(generator)
    visitor.visit(sexp)
    
    generator.program
  end
end