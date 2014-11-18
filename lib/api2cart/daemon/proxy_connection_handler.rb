module Api2cart::Daemon
  class ProxyConnectionHandler
    def handle_proxy_connection(client_socket)
      http_message = read_http_message(client_socket)
      response = send_request_to_remote_server(http_message.request_host, http_message.request_port, http_message.message)
      send_response_to_client(client_socket, response)
    end

    protected

    def read_http_message(socket)
      HTTPMessageReader.new(socket).read_http_message
    end

    def send_request_to_remote_server(host, port, request)
      remote_server_socket = Celluloid::IO::TCPSocket.new host, port
      remote_server_socket.write request
      read_http_message(remote_server_socket).message
    end

    def send_response_to_client(client_socket, response)
      client_socket.write response
      client_socket.close
    end
  end
end
