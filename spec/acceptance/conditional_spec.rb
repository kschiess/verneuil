require 'spec_helper'

describe "Conditionals" do
  SpecConditionalContext = Class.new(Struct.new(:a))
  
  context "with a==true" do
    let(:context) { SpecConditionalContext.new(true) }
    it "should echo true" do
      flexmock(context).should_receive(:echo).with(true).once.
        and_return(42)
      
      process(sample('conditional.rb'), context).run.should == 42
    end 
  end
  context "with a==false" do
    let(:context) { SpecConditionalContext.new(false) }
    it "should echo false" do
      flexmock(context).should_receive(:echo).with(false).once.
      and_return(43)
      
      process(sample('conditional.rb'), context).run.should == 43
    end 
  end
end