require 'spec_helper'

describe Verneuil::Program do
  let(:program) { described_class.new }
  describe "<- #add_method(klass, name, adr)" do
    it "should handle addition of implicit methods" do
      program.lookup_method(nil, :foo).should be_nil
      program.add_method(nil, :foo, flexmock(:adr))
      
      method = program.lookup_method(nil, :foo)
      method.should_not be_nil
    end 
    it "should handle addition of explicit methods (associated to a class)" do
      program.lookup_method(:Foo, :bar).should be_nil
      program.add_method(:Foo, :bar, flexmock(:adr))

      method = program.lookup_method(:Foo, :bar)
      method.should_not be_nil
    end 
  end
end