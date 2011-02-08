require 'spec_helper'

describe Verneuil::Program do
  let(:program) { described_class.new }
  describe "<- #add_implicit_method(name, adr)" do
    it "should add a method to the implicit methods" do
      program.lookup_method(nil, :foo).should be_nil
      program.add_implicit_method(:foo, flexmock(:adr))
      
      method = program.lookup_method(nil, :foo)
      method.should_not be_nil
    end 
  end
end