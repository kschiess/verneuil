require 'spec_helper'

describe "Simple method calls" do
  class SimpleContext < Struct.new(:a)
  end
  
  context "with a==true" do
    let(:context) { SimpleContext.new(true) }
    it "should echo true" do
      flexmock(context).should_receive(:echo).with(true).once.
        and_return(42)
      
      process(sample('conditional.rb'), context).run.should == 42
    end 
  end
  context "with a==false" do
    let(:context) { SimpleContext.new(false) }
    it "should echo false" do
      flexmock(context).should_receive(:echo).with(false).once.
      and_return(43)
      
      process(sample('conditional.rb'), context).run.should == 43
    end 
  end
end