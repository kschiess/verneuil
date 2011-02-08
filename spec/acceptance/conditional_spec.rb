require 'spec_helper'

describe "Conditionals" do
  SpecConditionalContext = Class.new(Struct.new(:a))
  
  describe "01" do
    context "with a==true" do
      let(:context) { SpecConditionalContext.new(true) }
      it "should echo true" do
        flexmock(context).should_receive(:p).with(true).once.
          and_return(42)

        process(sample('conditional_01.rb'), context).run.should == 42
      end 
    end
    context "with a==false" do
      let(:context) { SpecConditionalContext.new(false) }
      it "should echo false" do
        flexmock(context).should_receive(:p).with(false).once.
        and_return(43)

        process(sample('conditional_01.rb'), context).run.should == 43
      end 
    end
  end
  describe "02" do
    it "should return 1" do
      process(sample('conditional_02.rb'), nil).run.should == 1
    end 
  end
end 