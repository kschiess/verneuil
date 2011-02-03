require 'spec_helper'

describe Verneuil::Process do
  let(:context) { flexmock(:context) }
  # Spawns a new process that runs program.
  def process(program)
    Verneuil::Process.new(program, context)
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
        g.implicit_call :foo, 0
      end
      
      context.should_receive(:foo => :return_value).once
      process(program).run.should == :return_value
    end 
  end
end