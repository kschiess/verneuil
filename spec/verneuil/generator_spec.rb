require 'spec_helper'

describe Verneuil::Generator do
  let(:generator) { described_class.new }
  subject { generator.program.instructions }
  
  context "foo(:bar, :baz) (handles any kind of instruction)" do
    before(:each) { generator.foo(:bar, :baz) }
     
    it { should == [[:foo, :bar, :baz]]}
  end
end