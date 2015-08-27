require 'spec_helper'

describe Verneuil::Generator do
  let(:generator) { described_class.new }
  let(:subject) { generator.program.instructions }
  
  context "foo(:bar, :baz) (handles any kind of instruction)" do
    before(:each) { generator.dup(:bar, :baz) }
     
    it { should == [[:dup, :bar, :baz]]}
  end
  describe "<- #fwd_adr" do
    subject { generator.fwd_adr }
    it { should be_kind_of(Verneuil::Address) }
  end
  describe "<- #abs_adr(n)" do
    let(:subject) { generator.abs_adr(10) }
    it { should be_kind_of(Verneuil::Address) }
    it { subject.ip.should == 10 }
  end
  describe "<- #resolve(adr)" do
    let!(:adr) { generator.fwd_adr }
    before(:each) { generator.dup; generator.jump }
    before(:each) { generator.resolve(adr) }
    
    subject { adr }
    it { should be_kind_of(Verneuil::Address) }
    it { subject.ip.should == 2 }
  end
end