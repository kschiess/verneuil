require 'spec_helper'

describe "Local variables" do
  class SpecLocalVarContext
  end
  
  context "101" do
    let(:context) { SpecLocalVarContext.new }
    it "should run and set all variables" do
      process(sample('local_variables_01.rb'), context).run.should == 7
    end 
  end
end