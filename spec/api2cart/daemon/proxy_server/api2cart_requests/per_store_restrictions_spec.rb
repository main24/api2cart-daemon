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
    let(:api_key) { 's3krit' }

    def request_url(key)
      "http://localhost:4096/v1.0/product.count.json?api_key=#{api_key}&store_key=#{key}"
    end

    context 'when I make serial requests' do
      let(:mock_server) { MockServer.new(4096, '') }

      def make_request_to_store_with_key_of(key)
        HTTP.via('localhost', 2048).get request_url(key)
      end

      context 'when I make a request to some store' do
        before { make_request_to_store_with_key_of 'first' }

        it 'closes session before the request' do
          expect(mock_server.request_paths).to eq [
                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                  ]
        end

        context 'when I make second request to the same store' do
          before { make_request_to_store_with_key_of 'first' }

          it 'sends the request right away' do
            expect(mock_server.request_paths.count).to eq 3
            expect(mock_server.request_paths.last).to eq '/v1.0/product.count.json?api_key=s3krit&store_key=first'
          end

          context 'when I make a request to another store after that' do
            before { make_request_to_store_with_key_of 'second' }

            it 'closes session before the request' do
              expect(mock_server.request_paths.count).to eq 5
              expect(mock_server.request_paths.last(2)).to eq [
                                                               '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=second',
                                                               '/v1.0/product.count.json?api_key=s3krit&store_key=second'
                                                              ]
            end

            context 'when I send three more requests to the first store (5 totally)' do
              before do
                3.times { make_request_to_store_with_key_of 'first' }
              end

              it 'sends them right away' do
                expect(mock_server.request_paths.count).to eq 8
                expect(mock_server.request_paths.last(3)).to eq [
                                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                                ]
              end

              context 'when I send 6th request to the first store' do
                before { make_request_to_store_with_key_of 'first' }

                it 'closes session before the request' do
                  expect(mock_server.request_paths.count).to eq 10
                  expect(mock_server.request_paths.last(2)).to eq [
                                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                                  ]
                end

                context 'when I send four more requests to the second store (5 totally too)' do
                  before do
                    4.times { make_request_to_store_with_key_of 'second' }
                  end

                  it 'sends them right away' do
                    expect(mock_server.request_paths.count).to eq 14
                    expect(mock_server.request_paths.last(4)).to eq [
                                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=second',
                                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=second',
                                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=second',
                                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=second'
                                                                    ]
                  end

                  context 'when I send 6th request to the second store' do
                    before { make_request_to_store_with_key_of 'second' }

                    it 'closes session before the request' do
                      expect(mock_server.request_paths.count).to eq 16
                      expect(mock_server.request_paths.last(2)).to eq [
                                                                       '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=second',
                                                                       '/v1.0/product.count.json?api_key=s3krit&store_key=second'
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

    context 'when I make parallel requests' do
      let(:mock_server) { InspectableMockServer.new(4096, '') }

      def make_async_request_to_store_with_key_of(key)
        make_async_request request_url(key)
      end

      it 'sends requests only after session is closed' do
        make_async_request_to_store_with_key_of('first')
        mock_server.wait_for_number_of_requests(1)

        expect(mock_server.request_paths).to eq ['/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first']

        mock_server.respond_to_first
        mock_server.wait_for_number_of_requests(2)
        expect(mock_server.request_paths).to eq [
                                                 '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                ]
      end

      it 'closes session only after all current requests are done' do
        mock_server.dont_hold_requests!
        request_threads = 4.times.map { make_async_request_to_store_with_key_of('first') }
        request_threads.each(&:join)
        mock_server.hold_requests!

        2.times { make_async_request_to_store_with_key_of('first') }
        mock_server.wait_for_number_of_requests(6)  # one closing request and 5 genuine requests

        expect(mock_server.request_paths).to eq [
                                                 '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                ]

        mock_server.respond_to_first # release 5th genuine request

        mock_server.wait_for_number_of_requests(7)  # one closing request and 5 genuine requests

        expect(mock_server.request_paths).to eq [
                                                 '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                 '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first'
                                                ]
      end

      context 'when I do two requests to one store simultaneously' do
        before { mock_server.dont_hold_requests! }

        it 'closes session only once' do
          request_threads = 2.times.map { make_async_request_to_store_with_key_of('first') }
          request_threads.each(&:join)

          expect(mock_server.request_paths).to eq [
                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                  ]
        end
      end

      context 'when I do 7 requests to one store simultaneously' do
        before { mock_server.dont_hold_requests! }

        it 'it closes session after each 5 requests' do
          request_threads = 7.times.map { make_async_request_to_store_with_key_of('first') }
          request_threads.each(&:join)

          expect(mock_server.request_paths).to eq [
                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                  ]
        end
      end

      context 'when I make 11 requests to one store simultaneously' do
        before { mock_server.dont_hold_requests! }

        it 'it closes session after each 5 requests' do
          request_threads = 11.times.map { make_async_request_to_store_with_key_of 'first' }
          request_threads.each(&:join)

          expect(mock_server.request_paths).to eq [
                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=first',
                                                   '/v1.0/product.count.json?api_key=s3krit&store_key=first'
                                                  ]
        end
      end
    end
  end
end
