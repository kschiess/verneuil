require 'spec_helper'

describe "Class methods" do
  describe "01" do
    it "should return 10" do
      process(sample('class_methods_01.rb'), nil).run.should == 10
    end 
  end
end