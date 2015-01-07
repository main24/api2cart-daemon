require_relative 'mock_server'

class InspectableMockServer < MockServer
  include Celluloid::Notifications

  attr_reader :request_queue

  def run_async
    self.request_queue = []
    self.request_callbacks = []
    self.hold_requests = true
    super
  end

  def respond_to_first
    request_queue.shift.signal
  end

  def respond_to_all
    respond_to_first until request_queue.empty?
  end

  def hold_requests!
    self.hold_requests = true
  end

  def dont_hold_requests!
    self.hold_requests = false
    respond_to_all
  end

  def wait_for_number_of_requests(number)
    if request_paths.size < number
      condition = Celluloid::Condition.new
      on_every_request { condition.signal if request_paths.size == number }
      condition.wait
    end
  end

  protected

  attr_writer :request_queue
  attr_accessor :hold_requests
  alias :hold_requests? :hold_requests
  attr_accessor :request_callbacks

  def on_every_request(&block)
    self.request_callbacks << block
  end

  def call_request_callbacks
    request_callbacks.each &:call
  end

  def handle_connection(client_socket)
    read_request client_socket
    call_request_callbacks
    hold_request if hold_requests?
    write_response client_socket
  end

  def hold_request
    Celluloid::Condition.new.tap do |condition|
      request_queue << condition
      condition.wait
    end
  end
end
