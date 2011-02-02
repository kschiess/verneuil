
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
    
    # s(:call, nil, :foo, s(:arglist)) - Method calls with or without receiver.
    # 
    def accept_call(receiver, method_name, args)
      if receiver
        raise NotImplementedError
      else
        argc = visit(args)
        @generator.implicit_call method_name, argc
      end
    end
    
    # s(:arglist) - Argument lists. Needs to return the actual number of
    # arguments that we've compiled. 
    #
    def accept_arglist(*args)
      return args.size
    end
  end
  
  def compile(code)
    parser = RubyParser.new
    sexp = parser.parse(code)
    
    generator = Verneuil::Generator.new
    visitor   = Visitor.new(generator)
    visitor.visit(sexp)
    
    generator.instructions
  end
end