require 'spec_helper'

describe "Methods that take blocks" do
  context "101" do
    it "should run and return 4" do
      process(sample('method_with_block.rb'), nil).run.should == 4
    end 
  end
end