require 'spec_helper'

describe Verneuil::Scope do
  let(:context) { flexmock(:context) }
  let(:scope) { described_class.new(context, :a => 1, :b => 2) }

  context "when constructed with a parent" do
    let(:inner) { scope.child(:b => 3) }
    
    it "should return 1 for :a" do
      inner.lvar_get(:a).should == 1
    end
    it "should return 3 for :b" do
      inner.lvar_get(:b).should == 3
    end
    
    context "when setting :a, :b and :c" do
      before(:each) { 
        inner.lvar_set(:a, 42) 
        inner.lvar_set(:b, 42) 
        inner.lvar_set(:c, 42) 
      }
      it "should modify :a in outer scope" do
        inner.lvar_get(:a).should == 42
        scope.lvar_get(:a).should == 42
      end
      it "should leave :b in outer scope intact" do
        inner.lvar_get(:b).should == 42
        scope.lvar_get(:b).should == 2
      end
      it "should set :c only in inner scope" do
        inner.lvar_get(:c).should == 42
        lambda { scope.lvar_get(:c) }.should raise_error
      end 
    end  
  end
  
  describe "<- #lvar_get(name)" do
    subject { scope.lvar_get(:a) }
    it { should == 1 }
  end
  describe "<- #lvar_set(name, value)" do
    it "should set the instance variables value" do
      scope.lvar_set(:a, 42)
      scope.lvar_get(:a).should == 42
    end 
  end
  
  describe "delegation" do
    it "should delegate method calls to context" do
      context.should_receive(:name).with(:arg1, :arg2).and_return 13

      scope.method_call(:name, :arg1, :arg2).should == 13
    end 
  end
end