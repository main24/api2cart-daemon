module Api2cart::Daemon
  class AntiThrottler
    def initialize
      self.requests_currently_running = []
      self.waiting_queue = []
    end

    def prevent_throttling
      guard_from_exceeding_total_simultaneous_request_count do
        yield
      end
    end

    protected

    def guard_from_exceeding_total_simultaneous_request_count(&block)
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

    attr_accessor :waiting_queue
    attr_accessor :requests_currently_running
  end
end
