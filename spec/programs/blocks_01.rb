def foo(&block)
  p :foo_s
  block.call(:foo)
  p :foo_e
end

def bar(&block)
  p :bar_s
  foo do |name|
    p :bar_b_s
    block.call(name)
    p :bar_b_e
  end
  p :bar_e
end

bar do |n1|
  p n1
end
    
# should print
# :bar_s
# :foo_s
# :bar_b_s
# :foo
# :bar_b_e
# :foo_e
# :bar_e

  