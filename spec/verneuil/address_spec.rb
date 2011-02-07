require 'spec_helper'

describe Verneuil::Address do
  let(:generator) { flexmock(:generator) }
  let(:address) { described_class.new(4, generator) }
  
  describe "<- #resolve" do
    it "should resolve the address to point to the generators current address" do
      generator.should_receive(:resolve).with(address).once
      address.resolve
    end 
  end
  describe "<- ==(other)" do
    let(:other) { described_class.new(4, flexmock(:generator)) }
    it "should be equal to other addresses that have a different generator" do
      address.should == other
    end 
  end
end