require 'spec_helper'

describe "Methods" do
  class SpecMethCallContext < Struct.new(:n)
  end
  
  context "101" do
    let(:context) { SpecMethCallContext.new }
    it "should run and compute fibonacci series correctly" do
      c = SpecMethCallContext.new(4)
      process(sample('calls.rb'), c).run.should == 3 

      c = SpecMethCallContext.new(10)
      process(sample('calls.rb'), c).run.should == 55
    end 
  end
end