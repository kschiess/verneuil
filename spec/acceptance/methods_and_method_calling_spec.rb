require 'spec_helper'

describe "Methods" do
  class SpecMethCallContext
    attr_reader :n
    def initialize(n)
      super()
      @n = n
    end
  end
  
  context "101" do 
    it "should run and compute fibonacci series correctly" do
      # Ok, so this is f-d up, default values as variable contents... but it works.
      c = SpecMethCallContext.new(4)
      process(sample('calls.rb'), c).run.should == 3 

      c = SpecMethCallContext.new(10)
      process(sample('calls.rb'), c).run.should == 55
    end 
  end
end