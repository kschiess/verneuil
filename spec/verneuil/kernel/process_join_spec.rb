require 'spec_helper'

describe "in V: Process#join" do
  it "should halt execution until the child process exits" do
    code = "c=fork { 42 }; c.join"
    parent = process(code, nil)

    # Run the parent for a while - it should wait for child 'c'
    100.times do 
      parent.step
    end
    parent.should_not be_halted
    parent.children.should have(1).child

    child = parent.children.first
    
    # This essentially kills the child
    child.ip = -1
    10.times do 
      parent.step
    end
    parent.should be_halted
    child.should be_halted
  end 
end