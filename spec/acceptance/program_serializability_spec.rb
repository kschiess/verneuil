require 'spec_helper'

describe "Program serializability" do
  Dir[sample_path('*.rb')].each do |sample_name|
    
    # Some samples that cannot be run without setup
    short_name = File.basename(sample_name, '.rb')
    
    # Exceptions that cannot be run during this test.
    next if short_name == 'simple_methods'
    next if short_name == 'fork_01'
    
    describe '"' + short_name + '"' do
      it "should serialize at every step of execution" do
        p = process(File.read(sample_name), nil)
        
        until p.halted?
          p.step
          
          Marshal.dump p
        end
      end 
    end
  end
end