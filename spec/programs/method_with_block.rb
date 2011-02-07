
def foo(&block)
  block.call + 1
end

a = 3

n = foo do
  a
end

n