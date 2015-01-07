module RequestHelper
  # TODO: extract PROXY_PORT
  def make_async_request(request_url)
    Thread.new { HTTP.via('localhost', 2048).get(request_url) }
  end
end
