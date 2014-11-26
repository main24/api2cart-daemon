module Api2cart::Daemon
  class TotalSessionCountGuard
    def initialize
      self.requests_currently_running = []
      self.waiting_queue = []
    end

    def guard
      if requests_currently_running.count >= 20
        wait_in_queue!
      end

      response = run_request { yield }

      move_queue!

      response
    end

    protected

    attr_accessor :requests_currently_running
    attr_accessor :waiting_queue

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
