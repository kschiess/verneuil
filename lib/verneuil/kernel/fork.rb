
# Fork the current Verneuil process. Returns the new process instance to the
# caller; never exits the block in the child. 
#
# Example: (V-code)
#   child = fork do 
#     # do forked stuff here
#   end
#
Verneuil::Process.kernel_method nil, :fork do |process, _|
  block = process.current_block

  process.fork_child(block)
end