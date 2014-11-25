require 'http'

module Api2cart::Daemon
  class AntiThrottler
    def initialize
      self.requests_currently_running = []
      self.waiting_queue = []
      self.stores_quota = Hash.new(0)
    end

    def prevent_throttling(http_message)
      guard_from_exceeding_allowed_total_simultaneous_request_count do
        guard_from_exceeding_allowed_requests_per_store(http_message) do
          yield
        end
      end
    end

    protected

    attr_accessor :waiting_queue
    attr_accessor :requests_currently_running

    attr_accessor :stores_quota

    def guard_from_exceeding_allowed_requests_per_store(http_message)
      store_key = http_message.request_params['store_key']
      if stores_quota[store_key] == 0
        close_session(store_key, http_message.request_host, http_message.request_port)
        stores_quota[store_key] = 5
      end

      stores_quota[store_key] -= 1
      yield
    end

    def close_session(store_key, request_host, request_port)
      HTTP.get "http://#{request_host}:#{request_port}/v1.0/cart.disconnect.json?store_key=#{store_key}"
    end

    def guard_from_exceeding_allowed_total_simultaneous_request_count(&block)
      if requests_currently_running.count >= 20
        wait_in_queue!
      end

      response = run_request(&block)

      move_queue!

      response
    end

    def run_request(&block)
      token = Object.new
      requests_currently_running << token

      response = yield

      requests_currently_running.delete token

      response
    end

    def move_queue!
      return if waiting_queue.empty?

      first_in_waiting_queue = waiting_queue.shift
      first_in_waiting_queue.signal
    end

    def wait_in_queue!
      condition = Celluloid::Condition.new
      waiting_queue << condition
      condition.wait
    end
  end
end
