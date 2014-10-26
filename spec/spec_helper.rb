
require 'rspec'
require 'stringio'
require 'corl'

#*******************************************************************************

RSpec.configure do |config|
  config.mock_framework = :rspec
  config.color_enabled  = true
  config.formatter      = 'documentation'
end