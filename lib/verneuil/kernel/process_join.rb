
# Joins the V-process. This means that the joining process will be stopped
# until the joinee halts. Returns the process return value. 
#
# Running this method only makes sense on childs of the current process. 
#
# Example: 
#   child = fork { ...; 42 }
#   child.join # waits and eventually returns 42
#
Verneuil::Process.kernel_method :'Verneuil::Process', :join do |parent, child|
  
end