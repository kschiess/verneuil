require 'spec_helper'

describe "Simple method calls" do
  class SimpleContext
    def foo; end
    def bar(a); end
    def baz(a,b,c); c; end
  end
  
  let(:context) { SimpleContext.new }
  
  it "should delegate calls without receiver to the context" do
    flexmock(context).
      should_receive(:foo).once.ordered.
      should_receive(:bar).with(1).once.ordered.
      should_receive(:baz).with(1,2,3).once.ordered
    
    verneuil = sample('simple_methods.rb')

    process(verneuil, context).run
  end
  it "should allow marshalling the vm between method calls" do
    code = sample('simple_methods.rb')

    p1 = process(code, context)
    p1.step

    p2 = Marshal.load(Marshal.dump(p1))
    p2.run.should == 3
  end 
end