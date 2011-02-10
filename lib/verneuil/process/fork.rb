
module Verneuil::Process::Forking
  def fork(process, &block)
    p process.pop(3)
    raise NotImplementedError
  end
  Verneuil::Process.register_method nil, :fork, :fork
end