
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
        raise NotImplementedError
      else
        argc = visit(args)
        @generator.implicit_call method_name, argc
      end
    end
    
    # s(:arglist, ARGUMENT, ARGUMENT) - Argument lists. Needs to return the
    # actual number of arguments that we've compiled. 
    #
    def accept_arglist(*args)
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
  end
  
  def compile(code)
    parser = RubyParser.new
    sexp = parser.parse(code)
    
    generator = Verneuil::Generator.new
    visitor   = Visitor.new(generator)
    visitor.visit(sexp)
    
    generator.program
  end
end