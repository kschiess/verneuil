class Fixnum
  def times(&block)
    i = 0
    while i<self
      block.call(i)
      i+= 1
    end
  end
  def upto(n)
    i = self
    while i<n
      block.call(i)
      i+= 1
    end
  end
end

s = 0
10.times do
  s += 1
end

s # => 10