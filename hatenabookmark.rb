require 'rubygems'
require 'pit'
require 'time'
require 'digest/sha1'
require 'net/http'
require 'uri'
require 'nkf'
require 'pp'

# wsse認証を行う
def wsse(hatena_id, password)
	# 一意な値(仮実装)
	nonce = [Time.now.to_i.to_s].pack('m').gsub(/\n/, '')
	# nonce作成時のタイムスタンプをISO-8601表記で記述したもの
	now = Time.now.utc.iso8601
	
	# SHA1ダイジェスト化した文字列をBase64エンコード
	digest = [Digest::SHA1.digest(nonce + now + password)].pack("m").gsub(/\n/, '')
	
	{ 'X-WSSE' => sprintf(
		%Q<UsernameToken Username="%s", PasswordDigest="%s", Nonce="%s", Created="%s">,
		hatena_id, digest, nonce, now)
	}
end

# はてブ登録用xmlを生成する
def getXml(link, summary)
	%Q(
	<entry xmlns="http://purl.org/atom/ns#">
		<title>dummy</title>
		<link rel="related" type="text/html" href="#{link}" />
		<summary type="text/plain">#{summary}</summary>
	</entry>
	)
end

b_url = ARGV.shift || abort("Usage: hatenabookmark.rb <url> <comment>")
b_comment = ARGV.shift

# エンドポイント
url = "http://b.hatena.ne.jp/atom/post"

# ユーザ情報読み込み
hatena = Pit.get("hatena", :require => {
	# はてなIDとパスワード
	"hatena_id" => "your hatena_id", 
	"password" => "your password", 
})
# pitを使わずにべた書き用
# hatena = {
#	hatena_id => HATENA_ID, 
#	password = PASSWORD
# }

# WSSE認証
header = wsse(hatena["hatena_id"], hatena["password"])
pp header

uri = URI.parse(url)
proxy_class = Net::HTTP::Proxy(ENV["PROXY"], 8080)
http = proxy_class.new(uri.host)
http.start do |http|
	# 読み込んだ文字列をutf-8に変換
	# b_url = NKF.nkf('-w', b_url)
	# b_comment = NKF.nkf('-w', b_comment)
	
	# エンドポイントへPOST
	print getXml(b_url, b_comment)
	print "\n"
	res = http.post(uri.path, getXml(b_url, b_comment), header)
	if res.code == "201" then
		print "Bookmark success: #{b_url}\n"
	else
		print "#{res.code} Error: #{b_url}\n"
	end
end
