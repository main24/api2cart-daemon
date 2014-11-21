require 'stringio'

class MockServer < Struct.new(:port, :response)
  include Celluloid::IO

  def run_async
    server_socket = TCPServer.new '', port
    async.accept_connections server_socket
  end

  def request_log
    request_logger.string
  end

  def request_paths
    @request_paths ||= []
  end

  protected

  def request_logger
    @request_logger ||= StringIO.new
  end

  def accept_connections(server_socket)
    loop { async.handle_connection server_socket.accept }
  end

  def handle_connection(client_socket)
    read_request client_socket
    write_response client_socket
  end

  def read_request(client_socket)
    request = client_socket.readpartial(16384)
    request_paths << request.lines.first.match(/^.+ (.+) HTTP\/1\.1/)[1]
    request_logger.write request
  end

  def write_response(client_socket)
    client_socket.write compose_http_response
    client_socket.close
  end

  def compose_http_response
    <<RESPONSE + response
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: #{response.bytesize}
Connection: close

RESPONSE
  end
end
