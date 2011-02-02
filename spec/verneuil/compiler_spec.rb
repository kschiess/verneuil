require 'spec_helper'

describe Verneuil::Compiler do
  let(:compiler) { described_class.new }
  
  context "a simple method call" do
    let(:code) { %Q(foo) }
    subject { compiler.compile(code) }

    it { should generate do |g|
      g.method_call 0
    end }
  end
end