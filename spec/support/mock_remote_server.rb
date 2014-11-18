require 'stringio'

class MockRemoteServer < Struct.new(:port, :response)
  include Celluloid::IO

  def run_async
    server_socket = TCPServer.new '', port
    async.accept_connections server_socket
  end

  def request_log
    request_logger.string
  end

  protected

  def request_logger
    @request_logger ||= StringIO.new
  end

  def accept_connections(server_socket)
    loop do
      client_socket = server_socket.accept
      request_logger.write client_socket.readpartial(16384)
      client_socket.write compose_http_response
      client_socket.close
    end
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
