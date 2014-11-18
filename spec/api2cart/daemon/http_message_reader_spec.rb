describe Api2cart::Daemon::HTTPMessageReader do
  let(:socket) { StringIO.new(message) }
  let(:http_message_reader) { Api2cart::Daemon::HTTPMessageReader.new(socket) }

  let(:http_message) { http_message_reader.read_http_message }

  context 'when message is a valid HTTP request' do
    describe 'raw HTTP message' do
      subject { http_message.message }

      let(:message) do
        <<MESSAGE
GET http://api.api2cart.com/v1.0/product.count.json HTTP/1.1
Host: api.api2cart.com
User-Agent: RubyHTTPGem/0.6.2

MESSAGE
      end

      it 'returns the full message' do
        should == message
      end

      context 'when message is very long' do
        let(:long_text) { '0' * Api2cart::Daemon::HTTPMessageReader::READ_BUFFER_SIZE * 3 }

        let(:message) do
          <<HEADERS + long_text
POST / HTTP/1.1
Host: localhost:4096
Content-Length: #{long_text.bytesize}

HEADERS
        end

        it 'parses it all not depending on buffer size' do
          should == message
        end
      end
    end

    describe 'request host' do
      subject { http_message.request_host }

      let(:message) do
        <<MESSAGE
GET http://api.api2cart.com/v1.0/product.count.json HTTP/1.1
Host: api.api2cart.com
User-Agent: RubyHTTPGem/0.6.2

MESSAGE
      end

      it 'parses request host from headers' do
        should == 'api.api2cart.com'
      end
    end

    describe 'request port' do
      subject { http_message.request_port }

      context 'when port is not specified' do
        let(:message) do
          <<MESSAGE
GET http://api.api2cart.com/v1.0/product.count.json HTTP/1.1
Host: api.api2cart.com
User-Agent: RubyHTTPGem/0.6.2

MESSAGE
        end

        it { should == 80 }
      end

      context 'when port is specified explicitly' do
        let(:message) do
          <<MESSAGE
GET http://localhost:4096 HTTP/1.1
Host: localhost:4096
User-Agent: RubyHTTPGem/0.6.2

MESSAGE
        end

        it 'parses port from headers' do
          should == '4096'
        end
      end
    end
  end

  context 'when message is a valid HTTP response' do
    subject { http_message.message }

    let(:message) do
      <<MESSAGE
HTTP/1.1 200 OK
Date: Tue, 18 Nov 2014 10:19:56 GMT
Server: Apache/2.2.27 (Unix) mod_ssl/2.2.27 OpenSSL/1.0.1e-fips mod_bwlimited/1.4 mod_fcgid/2.3.9
X-Powered-By: PHP/5.3.28
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0
Pragma: no-cache
Set-Cookie: PHPSESSID=61cc757b3cd2d0048f1796d8e27b0f34; expires=Tue, 18-Nov-2014 12:20:30 GMT; path=/
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: origin, x-requested-with, content-type
Access-Control-Allow-Methods: PUT, GET, POST, DELETE, OPTIONS
Transfer-Encoding: chunked
Content-Type: application/json; charset=utf-8

4b\r
{"return_code" : 0, "return_message": "", "result" : {"products_count":76}}\r
0\r
\r
MESSAGE
    end

    it 'returns the full message' do
      should == message
    end
  end
end
