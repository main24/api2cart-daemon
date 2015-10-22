require 'api2cart/daemon/version'
require 'api2cart/daemon/http_message_reader'
require 'api2cart/daemon/total_request_count_guard'
require 'api2cart/daemon/total_request_count_guard/request_counter'
require 'api2cart/daemon/requests_per_store_guard'
require 'api2cart/daemon/requests_per_store_guard/store_quotas'
require 'api2cart/daemon/requests_per_store_guard/session_closer'
require 'api2cart/daemon/anti_throttler'
require 'api2cart/daemon/proxy_connection_handler'
require 'api2cart/daemon/proxy_server'
require 'active_support/core_ext/module/delegation'
require 'syslog/logger'

module Api2cart
  module Daemon
    LOGGER = Syslog::Logger.new 'api2cart-daemon'
    @@total_request_quota = nil

    def self.total_request_quota=(total_request_quota)
      @@total_request_quota = total_request_quota
    end

    def self.total_request_quota
      (@@total_request_quota || ENV['API2CART_DAEMON_TOTAL_REQUEST_QUOTA'] || 20).to_i
    end

    def self.run(port)
      ProxyServer.new(port).run
    end

    def self.run_async(port)
      ProxyServer.new(port).run_async
    end
  end
end
