require 'net/http'
module GeoNetworkHelpers
  def post(uri, data)
    req = Net::HTTP::Post.new(uri)
    req.body = data
    req.content_type = 'multipart/form-data'
    res = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(req)
    }
    res
  end
end