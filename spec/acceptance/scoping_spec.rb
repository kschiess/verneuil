require 'spec_helper'

describe "Scoping" do
  class SpecScopingCtx < Hash
    alias_method :local_variable_get, :"[]"
    alias_method :local_variable_set, :"[]="
  end
  
  context "101" do
    it "should run and return 0" do
      c = SpecScopingCtx.new
      process(sample('scopes_01.rb'), c).run.should == 0 
    end 
  end
end