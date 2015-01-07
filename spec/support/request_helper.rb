module RequestHelper
  # TODO: extract PROXY_PORT
  def make_async_request(request_url)
    Thread.new { HTTP.via('localhost', 2048).get(request_url) }
  end

  def request_url(key)
    "http://localhost:4096/v1.0/product.count.json?api_key=s3krit&store_key=#{key}"
  end

  def request_to_random_store
    request_url rand
  end
end
