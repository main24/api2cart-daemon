describe Api2cart::Daemon, 'happy path' do
  let(:mock_server) { MockServer.new(4096, 'I am a mock server') }
  let(:daemon_proxy) { Api2cart::Daemon::ProxyServer.new(2048) }

  before do
    Celluloid.shutdown
    Celluloid.boot
  end

  before do
    mock_server.run_async
    daemon_proxy.run_async
  end

  after do
    Celluloid::Actor.kill(daemon_proxy)
    Celluloid::Actor.kill(mock_server)
  end

  shared_examples 'HTTP proxy server' do
    let!(:proxy_response) { HTTP.via('localhost', 2048).get(request_url).to_s }

    it 'proxies request to remote server' do
      expect(proxy_response).to eq("I am a mock server")
      expect(mock_server.request_log).to eq(expected_request_log)
    end
  end

  context 'when URL is normalized' do
    let(:request_url) { 'http://localhost:4096/' }

    let(:expected_request_log) do
      <<EXPECTED_SERVER_LOG
GET / HTTP/1.1\r
Host: localhost:4096\r
User-Agent: RubyHTTPGem/0.6.2\r
\r
EXPECTED_SERVER_LOG
    end

    include_examples 'HTTP proxy server'
  end

  context 'when URL is not normalized' do
    let(:request_url) { 'http://localhost:4096' }

    let(:expected_request_log) do
      <<EXPECTED_SERVER_LOG
GET / HTTP/1.1\r
Host: localhost:4096\r
User-Agent: RubyHTTPGem/0.6.2\r
\r
EXPECTED_SERVER_LOG
    end

    include_examples 'HTTP proxy server'
  end

  context 'when URL contains path and query' do
    let(:request_url) { 'http://localhost:4096/path?key=value&another_key=another_value' }

    let(:expected_request_log) do
      <<EXPECTED_SERVER_LOG
GET /path?key=value&another_key=another_value HTTP/1.1\r
Host: localhost:4096\r
User-Agent: RubyHTTPGem/0.6.2\r
\r
EXPECTED_SERVER_LOG
    end

    include_examples 'HTTP proxy server'
  end
end
