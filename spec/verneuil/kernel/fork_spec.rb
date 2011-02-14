require 'spec_helper'

describe "in V: Kernel#fork" do
  context "after running a program that forks" do
    let(:code)    { "fork { 42 }" }
    let(:program) { Verneuil::Compiler.compile(code).program }
    let(:process) { Verneuil::Process.new(program, nil) }
    let!(:result) { process.run }
    
    it "should return an instance of Process" do
      result.should be_instance_of(Verneuil::Process)
      result.run.should == 42
    end
  end
end