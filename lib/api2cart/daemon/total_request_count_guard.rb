module Api2cart::Daemon
  class TotalRequestCountGuard
    def initialize
      self.request_counter = RequestCounter.new
      self.waiting_queue = []
    end

    def guard
      wait_in_queue! if request_counter.request_count >= 20
      response = yield
      move_queue!
      response
    end

    protected

    attr_accessor :requests_currently_running, :waiting_queue, :request_counter

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
