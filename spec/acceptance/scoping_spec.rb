require 'spec_helper'

describe "Scoping" do
  class SpecScopingCtx < Hash
  end
  
  context "101" do
    it "should run and return 0" do
      c = SpecScopingCtx.new
      process(sample('scopes_01.rb'), c).run.should == 0 
    end 
  end
end