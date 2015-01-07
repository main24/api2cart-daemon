module Api2cart::Daemon
  class RequestsPerStoreGuard::SessionCloser < Struct.new(:store_quotas, :currently_running_requests)
    def initialize(*args)
      super
      self.closing_requests = {}
    end

    def close_session_or_wait_for_closure(store_key, api_key, request_host, request_port)
      unless already_closing_session?(store_key)
        close_session(store_key, api_key, request_host, request_port)
      else
        puts "#{store_key} is waiting for quota"
        wait_for_closure(store_key)
      end
    end

    protected

    attr_accessor :closing_requests

    def already_closing_session?(store_key)
      closing_requests.key? store_key
    end

    def wait_for_closure(store_key)
      closing_requests[store_key].wait
    end

    def closing_requests_url(store_key, api_key, request_host, request_port)
      "http://#{request_host}:#{request_port}/v1.0/cart.disconnect.json?api_key=#{api_key}&store_key=#{store_key}"
    end

    def wait_for_current_store_requests_to_complete(store_key)
      currently_running_requests[store_key].each(&:wait)
    end

    def close_session(store_key, api_key, request_host, request_port)
      condition = Celluloid::Condition.new
      closing_requests[store_key] = condition

      wait_for_current_store_requests_to_complete(store_key)

      puts "Closing #{store_key}..."
      HTTP.get(closing_requests_url(store_key, api_key, request_host, request_port), socket_class: Celluloid::IO::TCPSocket)
      puts "...closed #{store_key}"
      closing_requests.delete store_key

      store_quotas.replenish_quota! store_key

      condition.broadcast
    end
  end
end
