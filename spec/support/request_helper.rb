module RequestHelper
  # TODO: extract PROXY_PORT
  def make_async_request(request_url)
    Thread.new do
      HTTP.via('localhost', 2048).get(request_url)
    end.tap do
      sleep 0.05 # TODO: invent something more clever than this
    end
    # TODO: it should be a fibered client instead
  end
end
