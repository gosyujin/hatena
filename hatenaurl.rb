#!/bin/ruby
require 'net/http'
require 'uri'
# http://rubyforge.org/snippet/detail.php?type=snippet&id=148
require 'simplejsonparser'

short_url = ARGV.shift || abort("Usage: hatenautl.rb <short_url>")
# エンドポイント
url = "http://b.hatena.ne.jp/api/htnto/expand"

uri = URI.parse(url)
proxy_class = Net::HTTP::Proxy(ENV["PROXY"], 8080)
http = proxy_class.new(uri.host)
http.start do |http|
	res = http.get(uri.path + "?shortUrl=#{short_url}")
	if res.code == "200" then
		jsonparse = JsonParser.new.parse(res.body)
		if jsonparse["data"]["expand"][0]["error"].nil? then
			print "#{jsonparse["data"]["expand"][0]["long_url"]}\n"
		else
			print "No htn.to url.\n"
		end
	else
		print "#{res.code}\n"
	end
end
