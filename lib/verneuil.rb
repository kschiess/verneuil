
module Verneuil
  class NameError < StandardError; end
end

require 'verneuil/address'
require 'verneuil/method'
require 'verneuil/symbol_table'
require 'verneuil/block'
require 'verneuil/program'

require 'verneuil/generator'
require 'verneuil/compiler'

require 'verneuil/scope'
require 'verneuil/process'
