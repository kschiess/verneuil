require 'spec_helper'

describe Verneuil::Compiler do
  let(:compiler) { described_class.new }
  
  context "simple method call" do
    let(:code) { %Q(foo) }
    let(:program) { generate do |g|
      g.implicit_call :foo, 0
    end }
    subject { compiler.compile(code) }

    it { should == program }
  end
  context "block of code" do
    let(:code) { %Q(foo; bar; baz) }
    let(:program) { generate do |g|
      g.implicit_call :foo, 0
      g.pop 1
      g.implicit_call :bar, 0
      g.pop 1
      g.implicit_call :baz, 0
    end }
    subject { compiler.compile(code) }

    it { should == program }
  end
  context "if expression" do
    let(:code) { "if 1 then 2 else 3 end"}
    subject { compiler.compile(code) }
    let(:program) {
      generate { |g|
        g.load 1                        # 0
        g.jump_if_false g.abs_adr(4)    # 1
        g.load 2                        # 2
        g.jump g.abs_adr(5)             # 3
        g.load 3                        # 4
      }
    }
    
    it { should == program }
  end
  context "assignment" do
    let(:code) { "a = 1"}
    subject { compiler.compile(code) }
    let(:program) {
      generate { |g|
        g.load 1
        g.load :a
        g.dup 1
        g.implicit_call :local_variable_set, 2
      }
    }
    
    it { should == program }
  end
  context "call" do
    it "should specced" 
  end
end 