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
        g.call Verneuil::Address.new(2)
        g.halt
        g.load 2
        g.return 
        g.load 1
        g.return
      }
    }
    
    it "should terminate and return 2" do
      process(program).run.should == 2
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
  end
end