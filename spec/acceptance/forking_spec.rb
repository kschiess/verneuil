require 'spec_helper'

describe "Simple method calls" do
  it "should delegate calls without receiver to the context" do
    process(sample('fork_01.rb'), nil).run.should be_kind_of(Verneuil::Process)
  end
  it "should allow joining child processes" do
    process(sample('fork_02.rb'), nil).run.should == [1, 2, 0]
  end
end