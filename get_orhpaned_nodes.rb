#!/usr/bin/ruby

##
# written by Tim Meusel
##
# http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
# http://mislav.uniqpath.com/2013/07/ruby-openssl/
# http://stackoverflow.com/questions/5410682/parsing-a-json-string-in-ruby
# http://www.ruby-doc.org/stdlib-2.0/libdoc/json/rdoc/JSON.html
##
# prints all certnames of nodes without a report in the puppetdb
# tested on ruby1.9.1
##
require "net/http"
require 'json'

uri = URI.parse("https://puppetdb/v3/nodes")

# Full
http = Net::HTTP.new(uri.host, uri.port)

http.use_ssl = true

http.verify_mode = OpenSSL::SSL::VERIFY_PEER
http.cert_store = OpenSSL::X509::Store.new
http.cert_store.set_default_paths
# /var/lib/puppet/ssl/ca/ca_crt.pem from PuppetCA
http.cert_store.add_file('/home/bastelfreak/ca_crt.pem')

res = http.request(Net::HTTP::Get.new(uri.request_uri))
parsed = JSON.parse(res.body)

parsed.each do |node|
  puts node["name"] unless node["report_timestamp"]
end
