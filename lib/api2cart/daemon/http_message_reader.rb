require 'ostruct'
require 'http_parser'
require 'uri'
require 'active_support/core_ext/object/blank'

module Api2cart::Daemon
  class HTTPMessageReader < Struct.new(:socket)
    READ_BUFFER_SIZE = 16384

    def initialize(*args)
      super
      initialize_parser!
    end

    def read_http_message
      message = read_entire_message_from_socket!
      host, port = parse_host_and_port(parser.headers['Host'])
      OpenStruct.new message: message, request_host: host, request_port: port, request_url: parser.request_url, request_params: parse_query_params(parser.request_url)
    end

    protected

    attr_reader :parser

    def initialize_parser!
      @complete_http_message_received = false

      @parser = HTTP::Parser.new

      parser.on_message_complete = ->() do
        @complete_http_message_received = true
      end
    end

    def parse_query_params(request_url)
      query = URI.parse(request_url).query
      return if query.blank?
      Hash[URI::decode_www_form(query)]
    end

    def read_next_chunk
      socket.readpartial(READ_BUFFER_SIZE).tap do |chunk|
        parser << chunk
      end
    end

    def read_entire_message_from_socket!
      ''.tap do |raw_data|
        raw_data << read_next_chunk until complete_http_message_received?
      end
    end

    def complete_http_message_received?
      !! @complete_http_message_received
    end

    def parse_host_and_port(host_and_port)
      return nil if host_and_port.nil?

      host, port = host_and_port.split(':')
      port ||= 80
      [host, port]
    end
  end
end
