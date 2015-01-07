describe Api2cart::Daemon::ProxyServer do
  let(:mock_server) { InspectableMockServer.new(4096, '') }
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

  describe 'total simultaneous request count quota together with per-store quota' do
    context 'given a store' do
      let(:store_key) { 'the_store' }

      context 'when I make 20 requests to the store' do
        before do
          20.times { make_async_request(request_url(store_key)) }
          sleep 0.1
        end

        it 'holds all of them and requests per-store quota to the store' do
          expect(mock_server.request_paths).to eq ['/v1.0/cart.disconnect.json?api_key=s3krit&store_key=the_store']
        end

        context 'when I make 19 requests to other stores' do
          let!(:request_threads) do
            19.times.map { make_async_request(request_to_random_store) }
          end

          it 'lets them all in' do
            mock_server.wait_for_number_of_requests(20)
            expect(mock_server.request_paths.count).to eq 20
          end

          context 'when I 20th request to a random store (21st one in total)' do
            before do
              make_async_request(request_to_random_store)
              sleep 0.1
            end

            it 'does not let it in' do
              expect(mock_server.request_queue.count).to eq 20
            end
          end
        end

        context 'when the store acquires quota' do
          before do
            mock_server.respond_to_first
            mock_server.wait_for_number_of_requests(5)
            sleep 0.1
          end

          it 'allows 5 requests in' do
            expect(mock_server.request_paths).to eq [
                                                     '/v1.0/cart.disconnect.json?api_key=s3krit&store_key=the_store',
                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=the_store',
                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=the_store',
                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=the_store',
                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=the_store',
                                                     '/v1.0/product.count.json?api_key=s3krit&store_key=the_store'
                                                    ]
          end

          context 'when I make 15 requests to other stores' do
            let!(:request_threads) do
              15.times.map { make_async_request(request_to_random_store) }
              sleep 0.1
            end

            it 'lets them all in' do
              expect(mock_server.request_queue.count).to eq 20
            end

            context 'when I 16th request to a random store (21st one in total)' do
              before do
                make_async_request(request_to_random_store)
                sleep 0.05
              end

              it 'does not let it in' do
                expect(mock_server.request_queue.count).to eq 20
              end
            end
          end
        end
      end
    end

    context 'given 5 stores' do
      let(:store_keys) { %w{first second third fourth fifth} }

      context 'when I make 20 requests per each store' do
        before do
          store_keys.each do |store_key|
            20.times { make_async_request request_url(store_key) }
          end
        end

        context 'when each of them acquires quota' do
          before do
            mock_server.wait_for_number_of_requests(5)
            5.times { mock_server.respond_to_first }
            sleep 0.1
          end

          it 'allows no more than 20 requests in' do
            expect(mock_server.request_queue.count).to eq 20
          end
        end
      end
    end
  end
end
