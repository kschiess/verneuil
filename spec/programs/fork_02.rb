a = 1
child = fork do
  b = a - 1
  a += 1
  [a, b]   # 2, 0 if scoping & accesses worked
end

retval = child.join
[a, retval].flatten # 1, 2, 0 if scoping & accesses worked
