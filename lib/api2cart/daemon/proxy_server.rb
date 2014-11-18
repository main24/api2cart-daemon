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
      ProxyConnectionHandler.new.handle_proxy_connection(client_socket)
    end
  end
end
