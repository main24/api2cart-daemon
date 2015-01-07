module Api2cart::Daemon
  class RequestCounter
    attr_reader :request_count

    def initialize
      self.request_count = 0
    end

    def count_request
      self.request_count += 1
      yield
      self.request_count -= 1
    end

    protected

    attr_writer :request_count
  end
end
