describe Api2cart::Daemon::ProxyServer do
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

    sleep 0.05
  end

  context 'given maximum requests per store is 5' do
    context 'when I make a request to some store' do
      let(:mock_server) { MockServer.new(4096, '') }

      def make_request_to_store_with_key_of(key)
        request_url = "http://localhost:4096/v1.0/product.count.json?store_key=#{key}"
        HTTP.via('localhost', 2048).get(request_url)
      end

      before { make_request_to_store_with_key_of 'first' }

      it 'closes session before the request' do
        expect(mock_server.request_paths).to eq [
                                                 '/v1.0/cart.disconnect.json?store_key=first',
                                                 '/v1.0/product.count.json?store_key=first'
                                                ]
      end

      context 'when I make second request to the same store' do
        before { make_request_to_store_with_key_of 'first' }

        it 'sends the request right away' do
          expect(mock_server.request_paths.count).to eq 3
          expect(mock_server.request_paths.last).to eq '/v1.0/product.count.json?store_key=first'
        end

        context 'when I make a request to another store after that' do
          before { make_request_to_store_with_key_of 'second' }

          it 'closes session before the request' do
            expect(mock_server.request_paths.count).to eq 5
            expect(mock_server.request_paths.last(2)).to eq [
                                                             '/v1.0/cart.disconnect.json?store_key=second',
                                                             '/v1.0/product.count.json?store_key=second'
                                                            ]
          end

          context 'when I send three more requests to the first store (5 totally)' do
            before do
              3.times { make_request_to_store_with_key_of 'first' }
            end

            it 'sends them right away' do
              expect(mock_server.request_paths.count).to eq 8
              expect(mock_server.request_paths.last(3)).to eq [
                                                               '/v1.0/product.count.json?store_key=first',
                                                               '/v1.0/product.count.json?store_key=first',
                                                               '/v1.0/product.count.json?store_key=first'
                                                              ]
            end

            context 'when I send 6th request to the first store' do
              before { make_request_to_store_with_key_of 'first' }

              it 'closes session before the request' do
                expect(mock_server.request_paths.count).to eq 10
                expect(mock_server.request_paths.last(2)).to eq [
                                                                 '/v1.0/cart.disconnect.json?store_key=first',
                                                                 '/v1.0/product.count.json?store_key=first'
                                                                ]
              end

              context 'when I send four more requests to the second store (5 totally too)' do
                before do
                  4.times { make_request_to_store_with_key_of 'second' }
                end

                it 'sends them right away' do
                  expect(mock_server.request_paths.count).to eq 14
                  expect(mock_server.request_paths.last(4)).to eq [
                                                                   '/v1.0/product.count.json?store_key=second',
                                                                   '/v1.0/product.count.json?store_key=second',
                                                                   '/v1.0/product.count.json?store_key=second',
                                                                   '/v1.0/product.count.json?store_key=second'
                                                                  ]
                end

                context 'when I send 6th request to the second store' do
                  before { make_request_to_store_with_key_of 'second' }

                  it 'closes session before the request' do
                    expect(mock_server.request_paths.count).to eq 16
                    expect(mock_server.request_paths.last(2)).to eq [
                                                                     '/v1.0/cart.disconnect.json?store_key=second',
                                                                     '/v1.0/product.count.json?store_key=second'
                                                                    ]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
