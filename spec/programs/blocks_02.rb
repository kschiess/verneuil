# Demonstrates that block scoping follow ruby 1.9 rules. 

class Array
  def each(&block)
    i = 0
    while i<size
      block.call(self[i])
      i += 1
    end
    self
  end
end

a = []
[1,2,3].each do |el|
  a << el
  b = el
end
  
defined?(b)