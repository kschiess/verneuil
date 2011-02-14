require 'spec_helper'

describe Verneuil::Process do
  let(:sandbox) { Class.new(Verneuil::Process) }
  
  context "inside a sandbox for test isolation" do
    def foo(process, receiver)
    end

    it "should allow adding kernel methods and looking them up" do
      called = false
      sandbox.kernel_method(nil, :bar) { called = true }
      method = sandbox.symbols.lookup_method(nil, :bar)
      
      method.invoke(flexmock(:process), flexmock(:receiver))
      
      called.should == true
    end 
  end
end