require 'spec_helper'

describe "Methods that take blocks" do
  context "101" do
    it "should run and return 4" do
      process(sample('method_with_block.rb'), nil).run.should == 4
    end 
  end
  context "nesting blocks" do
    let(:output) { [] }
    def p(x)
      output << x
    end
    it "should print the correct order of statements" do
      process(sample('blocks_01.rb'), self).run
      output.should == [:bar_s, :foo_s, :bar_b_s, :foo, :bar_b_e, :foo_e, :bar_e]
    end 
  end
end