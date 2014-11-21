require_relative 'mock_server'

class InspectableMockServer < MockServer
  attr_reader :request_queue

  def run_async
    self.request_queue = []
    super
  end

  def respond_to_first
    request_queue.shift.signal
  end

  protected

  attr_writer :request_queue

  def handle_connection(client_socket)
    condition = Celluloid::Condition.new
    request_queue << condition

    read_request client_socket
    condition.wait
    write_response client_socket
  end
end
