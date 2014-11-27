require 'http'

module Api2cart::Daemon
  class SessionsPerStoreGuard
    def initialize
      self.stores_quota = Hash.new(0)
      self.closing_request_conditions = {}
    end

    def guard(store_key, api_key, request_host, request_port)
      puts ''
      puts "Request for #{store_key}"
      puts "Quota: #{stores_quota}"

      if can_make_request?(store_key)
        make_request(store_key) { yield }
      else
        close_session_or_wait_for_closure(store_key, api_key, request_host, request_port)
        try_again(store_key, api_key, request_host, request_port) { yield }
      end
    end

    protected

    attr_accessor :stores_quota
    attr_accessor :closing_request_conditions

    def try_again(store_key, api_key, request_host, request_port)
      guard(store_key, api_key, request_host, request_port) { yield }
    end

    def make_request(store_key)
      stores_quota[store_key] -= 1
      puts "Making request for #{store_key}"
      yield
    end

    def can_make_request?(store_key)
      stores_quota[store_key] >= 1
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
      closing_request_conditions.key? store_key
    end

    def wait_for_closure(store_key)
      closing_request_conditions[store_key].wait
    end

    def closing_request_url(store_key, api_key, request_host, request_port)
      "http://#{request_host}:#{request_port}/v1.0/cart.disconnect.json?api_key=#{api_key}&store_key=#{store_key}"
    end

    def close_session(store_key, api_key, request_host, request_port)
      condition = Celluloid::Condition.new
      closing_request_conditions[store_key] = condition

      puts "Closing #{store_key}..."
      HTTP.get(closing_request_url(store_key, api_key, request_host, request_port), socket_class: Celluloid::IO::TCPSocket)
      puts "...closed #{store_key}"
      closing_request_conditions.delete store_key

      stores_quota[store_key] = 5

      condition.broadcast
    end
  end
end
