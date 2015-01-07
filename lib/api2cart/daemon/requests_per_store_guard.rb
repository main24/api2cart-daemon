require 'http'

module Api2cart::Daemon
  class RequestsPerStoreGuard
    def initialize
      self.store_quotas = StoreQuotas.new
      self.closing_request = {}
      self.current_requests = Hash.new([])
    end

    def guard(store_key, api_key, request_host, request_port)
      puts ''
      puts "Request for #{store_key}"

      close_session_or_wait_for_closure(store_key, api_key, request_host, request_port) until store_quotas.has_quota?(store_key)

      make_request(store_key) { yield }
    end

    protected

    attr_accessor :store_quotas, :closing_request, :current_requests

    def make_request(store_key)
      store_quotas.use_quota! store_key

      puts "Making request for #{store_key}"

      condition = Celluloid::Condition.new
      current_requests[store_key] << condition
      result = yield

      condition.broadcast
      current_requests[store_key].delete condition

      result
    end

    def close_session_or_wait_for_closure(store_key, api_key, request_host, request_port)
      unless already_closing_session?(store_key)
        close_session(store_key, api_key, request_host, request_port)
      else
        puts "#{store_key} is waiting for quota"
        wait_for_closure(store_key)
      end
    end

    def already_closing_session?(store_key)
      closing_request.key? store_key
    end

    def wait_for_closure(store_key)
      closing_request[store_key].wait
    end

    def closing_request_url(store_key, api_key, request_host, request_port)
      "http://#{request_host}:#{request_port}/v1.0/cart.disconnect.json?api_key=#{api_key}&store_key=#{store_key}"
    end

    def wait_for_current_store_requests_to_complete(store_key)
      current_requests[store_key].each(&:wait)
    end

    def close_session(store_key, api_key, request_host, request_port)
      condition = Celluloid::Condition.new
      closing_request[store_key] = condition

      wait_for_current_store_requests_to_complete(store_key)

      puts "Closing #{store_key}..."
      HTTP.get(closing_request_url(store_key, api_key, request_host, request_port), socket_class: Celluloid::IO::TCPSocket)
      puts "...closed #{store_key}"
      closing_request.delete store_key

      store_quotas.replenish_quota! store_key

      condition.broadcast
    end
  end
end
