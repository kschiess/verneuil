require 'spec_helper'

describe Verneuil::Compiler do
  let(:compiler) { described_class.new }
  
  def generate(&block)
    g = Verneuil::Generator.new
    block.call(g)
    g.instructions
  end
  
  context "a simple method call" do
    let(:code) { %Q(foo) }
    let(:program) { generate do |g|
      g.implicit_call :foo, 0
    end }
    subject { compiler.compile(code) }

    it { should == program }
  end
end 