require 'http'

module Api2cart::Daemon
  class RequestsPerStoreGuard < Struct.new(:total_request_count_guard)
    def initialize(*args)
      super
      self.currently_running_requests = Hash.new { |hash, key| hash[key] = [] }
      self.store_quotas = StoreQuotas.new
      self.session_closer = SessionCloser.new store_quotas, currently_running_requests, total_request_count_guard
    end

    def guard(store_key, api_key, request_host, request_port)
      puts ''
      puts "Request for #{store_key}"

      session_closer.close_session_or_wait_for_closure(store_key, api_key, request_host, request_port) until store_quotas.has_quota?(store_key)

      make_request(store_key) { yield }
    end

    protected

    attr_accessor :store_quotas, :session_closer, :currently_running_requests

    def make_request(store_key)
      puts "Making request for #{store_key}"

      store_quotas.use_quota! store_key

      condition = Celluloid::Condition.new
      currently_running_requests[store_key] << condition

      result = total_request_count_guard.guard { yield }

      condition.broadcast
      currently_running_requests[store_key].delete condition

      result
    end
  end
end
