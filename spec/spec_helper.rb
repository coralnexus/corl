
require 'rspec'
require 'stringio'
require 'corl'

require 'corl_test_kernel'
require 'corl_mock_input'

#-------------------------------------------------------------------------------

RSpec.configure do |config|
  config.mock_framework = :rspec
  config.color_enabled  = true
  config.formatter      = 'documentation'
end