require 'spec_helper'

describe Verneuil::SymbolTable do
  let(:st) { described_class.new() }
  describe "<- #add_method(klass, name, adr) / lookup" do
    it "should handle addition of implicit methods" do
      st.lookup_method(nil, :foo).should be_nil
      
      st.add(flexmock(:method, :receiver => nil, :name => :foo))
      
      method = st.lookup_method(nil, :foo)
      method.should_not be_nil
    end 
    it "should handle addition of explicit methods (associated to a class)" do
      class Foo; end
      st.lookup_method(Foo.new, :bar).should be_nil
      st.add(flexmock(:method, :receiver => :Foo, :name => :foo))

      method = st.lookup_method(Foo.new, :bar)
      method.should_not be_nil
    end 
  end
end