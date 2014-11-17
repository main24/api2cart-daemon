require_relative File.join(__dir__, '../lib/api2cart/daemon')

require 'rspec/core'
require 'http'

Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "shared_examples/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.before do
    Celluloid.shutdown
    Celluloid.boot
  end
end
