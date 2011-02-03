
RSpec.configure do |config|
  config.mock_with :flexmock
end

require 'verneuil'

# Yields a generator to the block given and returns the generated program.
# 
def generate(&block)
  g = Verneuil::Generator.new
  block.call(g)
  g.program
end

