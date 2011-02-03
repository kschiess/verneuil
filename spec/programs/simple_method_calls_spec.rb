require 'spec_helper'

describe "Simple method calls" do
  let(:compiler) { Verneuil::Compiler.new }
  let(:context) { flexmock(:context) }
  
  def process(context, code)
    program = compiler.compile(code)
    Verneuil::Process.new(program, context)
  end
  
  it "should delegate calls without receiver to the context" do
    context.
      should_receive(:foo).once.ordered.
      should_receive(:bar).with(1).once.ordered.
      should_receive(:baz).with(1,2,3).once.ordered
    
    verneuil = <<-RUBY
    foo
    bar(1) 
    baz 1,2,3 # a comment
    RUBY

    process(context, verneuil).run
  end
  it "should allow marshalling the vm between method calls" do
    context.
      should_receive(:foo).once.ordered.
      should_receive(:bar).with(1).once.ordered.
      should_receive(:baz).with(1,2,3).once.ordered

    code = <<-RUBY
    foo
    bar(1) 
    baz 1,2,3 # a comment
    RUBY

    p1 = process(context, code)
    p1.step
    
    p2 = Marshal.load(Marshal.dump(p1))
    p2.run
  end 
end