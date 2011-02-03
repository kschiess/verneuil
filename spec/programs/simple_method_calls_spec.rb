require 'spec_helper'

describe "Simple method calls" do
  let(:compiler) { Verneuil::Compiler.new }
  let(:context) { flexmock(:context) }
  
  def run(context, code)
    program = compiler.compile(code)
    process = Verneuil::Process.new(program, context)
    process.run
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

    run(context, verneuil)
  end
end