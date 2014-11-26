module Api2cart::Daemon
  class AntiThrottler
    def initialize
      self.total_session_count_guard = TotalSessionCountGuard.new
      self.sessions_per_store_guard = SessionsPerStoreGuard.new
    end

    def prevent_throttling(http_message)
      guard_from_exceeding_allowed_total_simultaneous_request_count do
        guard_from_exceeding_allowed_requests_per_store(http_message) do
          yield
        end
      end
    end

    protected

    attr_accessor :total_session_count_guard
    attr_accessor :sessions_per_store_guard

    def guard_from_exceeding_allowed_requests_per_store(http_message)
      store_key = http_message.request_params['store_key']
      request_host = http_message.request_host
      request_port = http_message.request_port

      sessions_per_store_guard.guard(store_key, request_host, request_port) { yield }
    end

    def guard_from_exceeding_allowed_total_simultaneous_request_count
      total_session_count_guard.guard { yield }
    end
  end
end
