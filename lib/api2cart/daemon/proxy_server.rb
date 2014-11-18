require 'celluloid/io'

module Api2cart::Daemon
  class ProxyServer
    include Celluloid::IO

    def run(port)
      accept_connections bind_proxy_socket(port)
    end

    def run_async(port)
      async.accept_connections bind_proxy_socket(port)
    end

    protected

    def bind_proxy_socket(port)
      TCPServer.new('', port).tap do
        puts "API2Cart Daemon is running at 0.0.0.0:#{port}"
      end
    end

    def accept_connections(proxy_socket)
      loop { async.handle_connection proxy_socket.accept }
    end

    def handle_connection(client_socket)
      http_message = read_http_message(client_socket)
      response = send_request_to_remote_server(http_message.request_host, http_message.request_port, http_message.message)
      send_response_to_client(client_socket, response)
    end

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
