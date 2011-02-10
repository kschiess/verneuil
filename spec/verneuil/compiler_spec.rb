require 'spec_helper'

describe Verneuil::Compiler do
  let(:compiler) { described_class.new }

  context "literal nil" do
    let(:code) { %Q(nil) }
    let(:program) { generate do |g|
      g.load nil
    end }
    subject { compiler.compile(code) }

    it { should == program }
  end
  
  context "simple method call" do
    let(:code) { %Q(foo) }
    let(:program) { generate do |g|
      g.ruby_call_implicit :foo, 0
    end }
    subject { compiler.compile(code) }

    it { should == program }
  end
  context "method call on self" do
    let(:code) { "self.foo" }
    let(:program) { generate do |g|
      g.load_self
      g.ruby_call :foo, 0
    end }
    subject { compiler.compile(code) }

    it { should == program }
  end
  context "block of code" do
    let(:code) { %Q(foo; bar; baz) }
    let(:program) { generate do |g|
      g.ruby_call_implicit :foo, 0
      g.pop 1
      g.ruby_call_implicit :bar, 0
      g.pop 1
      g.ruby_call_implicit :baz, 0
    end }
    subject { compiler.compile(code) }

    it { should == program }
  end

  context "array construction" do
    let(:code) { "[1,2,3]"}
    subject { compiler.compile(code) }
    let(:program) {
      generate { |g|
        g.load 1
        g.load 2
        g.load 3
        g.load Array
        g.ruby_call :"[]", 3 
      }
    }
    
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
  context "while expression" do
    let(:code) { "body while test"}
    subject { compiler.compile(code) }
    let(:program) {
      generate { |g|
        adr_end = g.fwd_adr
        adr_test = g.current_adr

        # test
        g.ruby_call_implicit :test, 0
        g.jump_if_false adr_end
        
        # body
        g.ruby_call_implicit :body, 0
        
        g.jump adr_test
        adr_end.resolve
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
        g.dup 0
        g.lvar_set :a
      }
    }
    
    it { should == program }
  end
  context "or-assign" do
    let(:code) { "a ||= 1"}
    subject { compiler.compile(code) }
    let(:program) {
      generate { |g|
        adr_end = g.fwd_adr
        adr_else = g.fwd_adr
        
        g.test_defined :a
        g.jump_if_false adr_else
        
        g.ruby_call_implicit :a, 0
        g.jump adr_end
        
        adr_else.resolve
        g.load 1
        
        adr_end.resolve
        g.dup 0
        g.lvar_set :a
      }
    }
    
    it { should == program }
  end

  context "defined?(1)" do
    let(:code) { "defined?(1)"}
    let(:program) {
      generate { |g|
        g.load 'expression'
      }
    }
    it "should compile into the given program" do
      compiler.compile(code).should == program
    end 
  end
  context "defined?(a)" do
    let(:code) { "defined?(a)"}
    let(:program) {
      generate { |g|
        g.test_defined :a
      }
    }
    it "should compile into the given program" do
      compiler.compile(code).should == program
    end 
  end

  context "call" do
    let(:code) { "1.succ"}
    subject { compiler.compile(code) }
    let(:program) {
      generate { |g|
        g.load 1
        g.ruby_call :succ, 0
      }
    }
    
    it { should == program }
  end
  context "function definition" do
    let(:code) { "def foo(n); return n; 1; end; foo 1"}
    let(:program) {
      generate { |g|
        adr_end = g.fwd_adr
        g.jump adr_end
        g.lvar_set :n
        g.ruby_call_implicit :n, 0
        g.return 
        g.load 1
        g.return
        
        g.resolve adr_end
        g.load 1
        g.ruby_call_implicit :foo, 1
      }
    }
    subject { compiler.compile(code) }
    
    it { should == program }
    
    context "function :foo" do
      let(:program) { compiler.compile(code) }
      subject { program.lookup_method(nil, :foo) }
      
      its(:name)    { should == :foo }
      it "should point to the address of the function" do
        subject.address.ip.should == 1
      end 
    end
  end
  context "methods with block argument" do
    let(:code) { "def foo(&block); block.call(1); end; a=0; foo { a }" }
    let(:program) {
      generate { |g|
        adr_after_block = g.fwd_adr
        adr_after_fun = g.fwd_adr

        g.jump adr_after_fun
        
        adr_start_of_fun = g.current_adr
        
        # Function 
        g.load_block
        g.lvar_set :block
        
        # translates: block.call(1)
        g.load 1 
        g.ruby_call_implicit :block, 0
        g.ruby_call :call, 1
        g.return
        
        adr_after_fun.resolve 
        
        # translates: a = 0
        g.load 0
        g.dup 0
        g.lvar_set :a
        g.pop 1
        
        g.jump adr_after_block
        
        adr_start_of_block = g.current_adr
        
        # Block
        g.ruby_call_implicit :a, 0
        g.return
        
        adr_after_block.resolve
                
        # translates: foo { a }
        g.push_block adr_start_of_block
        g.ruby_call_implicit :foo, 0
        g.pop_block
      }
    }
    subject { compiler.compile(code) }

    it { should == program }
  end
  context "class methods" do
    let(:code) { "class Fixnum; def foo; succ; end end; 1.foo"}
    subject { compiler.compile(code) }
    let(:program) {
      generate { |g|
        adr_main = g.fwd_adr
        g.jump adr_main
        
        # foo body
        g.ruby_call_implicit :succ, 0
        g.return
        
        adr_main.resolve
        
        g.load 1
        g.ruby_call :foo, 0
      }
    }
    
    it { should == program }
  end

  describe "<- #compile" do
    it "should support multiple calls with different pieces of code" do
      other_compiler = Verneuil::Compiler.new
      
      compiler.compile 'foo'
      compiler.compile 'bar'
      
      other_compiler.compile 'foo; bar'
      
      compiler.program.should == compiler.program
    end
  end
end 