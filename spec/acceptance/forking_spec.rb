require 'spec_helper'

describe "Simple method calls" do
  it "should delegate calls without receiver to the context" do
    process(sample('fork_01.rb'), nil).run.should be_kind_of(Verneuil::Process)
  end
end