require 'spec_helper'

describe "in V: Process#join" do
  let(:code) { "c=fork { 42 }; c.join" }
  let(:parent) { process(code, nil) }

  it "should halt execution until the child process exits" do
    # Run the parent for a while - it should wait for child 'c'
    parent.step until parent.waiting?
      
    parent.should_not be_halted

    parent.children.should_not be_empty
    child = parent.children.first
        
    # This essentially kills the child
    child.ip = -1
    parent.group.run
    
    child.should be_halted
    parent.should be_halted
  end 
end