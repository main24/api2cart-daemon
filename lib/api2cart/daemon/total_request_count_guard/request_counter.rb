module Api2cart::Daemon
  class TotalRequestCountGuard::RequestCounter
    attr_reader :request_count

    def initialize
      self.request_count = 0
    end

    def count_request
      self.request_count += 1
      result = yield
      self.request_count -= 1

      result
    end

    protected

    attr_writer :request_count
  end
end
