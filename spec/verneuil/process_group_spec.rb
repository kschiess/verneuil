require 'spec_helper'

describe Verneuil::ProcessGroup do
  context "a parent with two children" do
    let(:parent)  { process(%Q(3), nil) }
    
    let!(:child1)  { parent.fork_child(block(parent, 0)) }
    let!(:child2)  { parent.fork_child(block(parent, 0)) }

    let(:group)   { parent.group }

    describe "<- #step" do
      it "should step all three processes" do
        parent.children.should have(2).childs

        3.times do
          group.step
        end

        parent.should be_halted
        child1.should be_halted
        child2.should be_halted
      end 
    end
  end
  context "a deep tree" do
    let(:parent)  { process(%Q(3; 4), nil) }
    before(:each) { 
      current = parent
      10.times do
        current = current.fork_child(block(current, 0))
      end
    }
    
    describe "<- #run" do
      it "should run until all processes are complete" do
        parent.group.run
        
        # Check if the parent has completed
        parent.should be_halted
        
        # Check if all subprocesses are complete as well
        child = parent
        while child
          child.should be_halted
          child = child.children.first
        end
      end 
    end
  end
end