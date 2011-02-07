require 'spec_helper'

describe Verneuil::Scope do
  let(:context) { flexmock(:context) }
  let(:scope) { described_class.new(context, :a => 1) }
  
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

  describe "<- #enter_scope" do
    it "should return a new scope" do
      scope.enter_scope.should be_kind_of(described_class)
    end
    
    describe "the returned scope" do
      let(:inner_scope) { scope.enter_scope }
      it "should not have variable :a defined" do
        lambda {
          inner_scope.lvar_get(:a)
        }.should raise_error(Verneuil::NameError) 
      end
    end
  end
  describe "<- #leave_scope" do
    let(:inner_scope) { scope.enter_scope }
    subject { inner_scope.leave_scope }
    it { should == scope }
    it "should still have :a" do
      subject.lvar_get(:a).should == 1
    end 
  end
end