require_relative 'mock_server'

=begin
It must be working without threads.
Just on fibers.
It must *return* control after each step.
Like so:

```
send request
server.accept_one_connection
....
server.respond
```

Hint: a client must be on fibers too.
=end

class InspectableMockServer < MockServer
  attr_reader :request_queue

  def run_async
    self.request_queue = []
    self.hold_requests = true
    super
  end

  def respond_to_first
    request_queue.shift.signal
    sleep(0.05) # TODO: get rid of this shame (join thread in specs?)
  end

  def respond_to_all
    request_queue.each(&:signal)
    request_queue.clear
  end

  def dont_hold_requests
    self.hold_requests = false
    respond_to_all
  end

  protected

  attr_writer :request_queue
  attr_accessor :hold_requests

  def handle_connection(client_socket)
    if hold_requests
      read_request client_socket
      hold_request
      write_response client_socket
    else
      super
    end
  end

  def hold_request
    Celluloid::Condition.new.tap do |condition|
      request_queue << condition
      condition.wait
    end
  end
end
