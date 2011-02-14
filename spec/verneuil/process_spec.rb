require 'spec_helper'

describe Verneuil::Process do
  let(:context) { flexmock(:context) }
  # Spawns a new process that runs program.
  def process(program)
    Verneuil::Process.new(program, context)
  end
  
  describe "function calls inside verneuil" do
    let(:program) {
      generate { |g|
        adr_fun = g.fwd_adr
        g.program.symbols.add Verneuil::Method.new(nil, :foo, adr_fun)
        
        g.ruby_call_implicit :foo, 0
        g.halt
        
        adr_fun.resolve
        g.load 2
        g.return 
        g.load 1    # sentinel to guard against a disfunctional return
      }
    }
    
    it "should terminate and return 2" do
      process(program).run.should == 2
    end 
  end
  describe "local variable access" do
    let(:program) {
      generate { |g|
        g.ruby_call_implicit :a, 0
      }
    }
    
    it "should return the value of :a" do
      p = Verneuil::Process.allocate
      
      s = flexmock(:scope)
      flexmock(p).should_receive(:scope => s)
      
      p.send :initialize, program, context
            
      s.should_receive(:lvar_exist?).with(:a).and_return(true)
      s.should_receive(:lvar_get).with(:a).and_return(42)
      
      p.run.should == 42
    end 
  end
  describe "self: refers to context outside of class methods" do
    let(:program) {
      generate { |g|
        g.load_self
        g.ruby_call :foo, 0
      }
    }
    
    it "should call :foo on the context" do
      context.should_receive(:foo => :bar).once
      process(program).run.should == :bar
    end 
  end

  describe "<- #run" do
    it "should stop as soon as the program is done" do
      empty = Verneuil::Program.new
      timeout(1) do
        process(empty).run
      end
    end 
    it "should execute a method call" do
      program = generate do |g|
        g.ruby_call_implicit :foo, 0
      end
      
      context.should_receive(:foo => :return_value).once
      process(program).run.should == :return_value
    end 
  end
  describe "<- #step" do
    it "should perform the next instruction and then quit" do
      program = generate do |g|
        g.ruby_call_implicit :foo, 0
        g.ruby_call_implicit :bar, 0
      end
      
      context.should_receive(:foo)
      context.should_receive(:bar).never
      process(program).step.should be_nil
    end
    it "should return a value once the process terminates" do
      program = generate do |g|
        g.ruby_call_implicit :foo, 0
      end
      p1 = process(program)
      
      context.should_receive(:foo => 42)
      p1.step.should == 42
      p1.should be_halted
    end 
    it "should halt the machine if the ip is negative" do
      program = generate do |g|
        g.ruby_call_implicit :foo, 0
      end
      p1 = process(program)
      
      p1.ip = -1
      p1.step
      p1.should be_halted
    end 
  end
end