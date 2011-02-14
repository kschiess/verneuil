a = 1
child = fork do
  b = a - 1
  a += 1
  [a, b]   # 2, 0 if scoping & accesses worked
end

child.join
[a, child.value].flatten # 2, 2, 0 if scoping & accesses worked
