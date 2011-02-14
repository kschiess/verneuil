require 'spec_helper'

describe Verneuil::Process do
  let(:sandbox) { Class.new(Verneuil::Process) }
  
  context "inside a sandbox for test isolation" do
    def foo(process, receiver)
    end

    it "should allow adding kernel methods and looking them up" do
      sandbox.register_method(nil, :bar, :foo)
      method = sandbox.symbols.lookup_method(nil, :bar)
      
      flexmock(self).should_receive(:foo).once
      method.invoke(flexmock(:process), flexmock(:receiver))
    end 
  end
end