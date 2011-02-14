
# Represents a method that can be called. 
#
class Verneuil::Method < Struct.new(:receiver, :name, :address)
  def invoke(process, recv_obj)
    if receiver
      process.call address, recv_obj
    else
      process.call address
    end
    throw :verneuil_code
  end
end