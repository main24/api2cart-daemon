describe Api2cart::Daemon, 'happy path' do
  before { Api2cart::Daemon.run_async 2048 }

  shared_examples 'it continues to serve' do
    before { MockRemoteServer.new(4096, 'I am a mock server', server_request_logger) }

    let(:proxy_response) { HTTP.via('localhost', 2048).get('http://localhost:4096').to_s }

    specify do
      expect(proxy_response).to eq("I am a mock server\n")
    end
  end

  context 'when it is a direct request, not proxying one' do
    let!(:response) { HTTP.get('http://localhost:2048').to_s }

    it 'returns nothing' do
      expect(response).to eq('')
    end

    include_examples 'it continues to serve'
  end

  context 'when request is recursive' do
    let!(:response) { HTTP.via('localhost', 2048).get('http://localhost:2048').to_s }

    it 'returns nothing' do
      expect(response).to eq('')
    end

    include_examples 'it continues to serve'
  end

  context 'when server is unreachable' do
    let!(:response) { HTTP.via('localhost', 2048).get('http://localhost:9999').to_s }

    it 'returns nothing' do
      expect(response).to eq('')
    end

    include_examples 'it continues to serve'
  end

  context 'when request is malformed' do
    before do
      client_socket = TCPSocket.new 'localhost', 2048
      client_socket.write 'ok google, where is London Eye?'
    end

    include_examples 'it continues to serve'
  end

  context 'when client suddenly breaks connection' do
    before do
      client_socket = TCPSocket.new 'localhost', 2048
      client_socket.close
    end

    include_examples 'it continues to serve'
  end
end
