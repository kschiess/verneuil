# A group of processes identified by their root process. 
#
class Verneuil::ProcessGroup
  def initialize(root)
    @root = root
    @counter = 0
  end
  
  # Make our root conform to the interface group#step implements.
  class Root < Struct.new(:process)
    def step
      process.step
      return true
    end
    
    def halted?
      process.halted?
    end
  end
  
  # Steps one of the processes in this group once. Returns true if all child 
  # process groups have made one step. 
  #
  def step
    list = processes
    idx =  @counter % list.size
    
    if list[idx].step
      @counter += 1
    end
    
    if @counter >= list.size
      @counter = 0
      return true
    end
    
    return false
  end
  
  # Runs this process group until all processes have halted.
  #
  def run
    until halted?
      step
    end
  end

  def halted?
    processes.all? { |p| p.halted? }
  end
  
  def processes
    [Root.new(@root)] + @root.children.map { |p| p.group }
  end
end