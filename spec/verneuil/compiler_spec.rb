require 'spec_helper'

describe Verneuil::Compiler do
  let(:compiler) { described_class.new }
  
  context "simple method call" do
    let(:code) { %Q(foo) }
    let(:program) { generate do |g|
      g.ruby_call_implicit :foo, 0
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
        g.dup 0
        g.lvar_set :a
      }
    }
    
    it { should == program }
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
        g.enter true
        g.lvar_set :n
        g.lvar_get :n
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
      before(:each) { compiler.compile(code) }
      subject { compiler.functions[:foo] }
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
        g.enter true
        g.load_block
        g.lvar_set :block
        
        # translates: block.call(1)
        g.load 1 
        g.lvar_get :block
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
        g.lvar_get :a
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