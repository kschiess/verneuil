require 'spec_helper'

describe Verneuil::Generator do
  let(:generator) { described_class.new }
  subject { generator.instructions }
  
  context "method_call(name, arg_count)" do
    before(:each) { generator.implicit_call(:foo, 42) }
     
    it { should == [[:implicit_call, :foo, 42]]}
  end
end