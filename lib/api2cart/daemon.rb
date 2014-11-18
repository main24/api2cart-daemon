require 'api2cart/daemon/version'
require 'api2cart/daemon/http_message_reader'
require 'api2cart/daemon/proxy_server'
require 'api2cart/daemon/proxy_connection_handler'
require 'active_support/core_ext/module/delegation'

module Api2cart
  module Daemon
    def self.run(port)
      ProxyServer.new.run(port)
    end

    def self.run_async(port)
      ProxyServer.new.run_async(port)
    end
  end
end
