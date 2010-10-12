#!/usr/bin/ruby
# Using GPL v2
# Author:: DongYuwei(mailto:newdongyuwei@gmail.com)
# 更新部分内容应对2010年7月25日飞信升级 

require 'uri'
require 'net/http'
require 'net/https'
require "socket"
require 'rexml/document'
require 'digest/md5'
require 'digest/sha1'
require "iconv"

class Fetion
	def initialize(phone_num , password)
		@phone_num = phone_num;
		@password = password;
		@domain = "fetion.com.cn";
		@login_xml = '<args><device type="PC" version="0" client-version="3.5.2540" /><caps value="simple-im;im-session;temp-group;personal-group" /><events value="contact;permission;system-message;personal-group" /><user-info attributes="all" /><presence><basic value="400" desc="" /></presence></args>';
		self.init
	end
	
	def init
		doc = REXML::Document.new(self.get_system_config())
		sipc_proxy = ""
		doc.elements.each("//sipc-proxy") do |element|  # using regexp should be faster
			sipc_proxy = element.text
		end
		@SIPC = SIPC.new(sipc_proxy);
		
		sipc_url = ""
		#ssi-app-sign-in
		doc.elements.each("//ssi-app-sign-in-v2") do |element|
			sipc_url = element.text
		end
		@fetion_num = self.get_fetion_num(self.SSIAppSignIn(sipc_url))
	end
	
	def login()
		request1 = sprintf("R %s SIP-C/2.0\r\nF: %s\r\nI: 1\r\nQ: 1 R\r\nL: %s\r\n\r\n",@domain, @fetion_num, @login_xml.length)
		request1 = request1 + @login_xml
		server_response = @SIPC.request(request1)
		@nonce = server_response.scan(/nonce="(.*)"/)[0][0]
		
		request2 = sprintf("R %s SIP-C/2.0\r\nF: %s\r\nI: 1\r\nQ: 2 R\r\nA: Digest response=\"%s\",cnonce=\"%s\"\r\nL: %s\r\n\r\n", @domain, @fetion_num, self.get_response(), @cnonce, @login_xml.length)
		request2 = request2 + @login_xml
		@SIPC.request(request2)
	end
	
	def send_sms(phone, sms_text)
		sms_text = Iconv.iconv("UTF-8","UTF-8",sms_text)[0]
		request = sprintf("M %s SIP-C/2.0\r\nF: %s\r\nI: 2\r\nQ: 1 M\r\nT: tel:%s\r\nN: SendSMS\r\nL: %s\r\n\r\n",@domain, @fetion_num, phone, sms_text.length)
		request = request + sms_text
		@SIPC.request(request)
	end
	
	def send_sms_to_self(sms_text)
		sms_text = Iconv.iconv("UTF-8","UTF-8",sms_text)[0]
		request = sprintf("M %s SIP-C/2.0\r\nF: %s\r\nI: 2\r\nQ: 1 M\r\nT: %s\r\nN: SendCatSMS\r\nL: %s\r\n\r\n",@domain, @fetion_num, @uri, sms_text.length)
		request = request + sms_text
		@SIPC.request(request)
	end

	def logout()
		logout_request = sprintf("R %s SIP-C/2.0\r\nF: %s\r\nI: 1 \r\nQ: 3 R\r\nX: 0\r\n\r\n", @domain, @fetion_num)
		@SIPC.request(logout_request)
	end
	
	def get_response()
		@cnonce = Digest::MD5.hexdigest(rand.to_s)
		key = Digest::MD5.digest(@fetion_num + ":" + @domain + ":" + @password)
		h1 = Digest::MD5.hexdigest(key + ":" + @nonce + ":" + @cnonce).upcase
		h2 = Digest::MD5.hexdigest("REGISTER:" + @fetion_num).upcase
		return Digest::MD5.hexdigest(h1+":" + @nonce + ":" + h2).upcase
	end
	
	def get_system_config()
		uri = URI.parse("http://nav.fetion.com.cn/nav/getsystemconfig.aspx")
		http = Net::HTTP.new(uri.host, uri.port)
		params = sprintf('<config><user mobile-no="%s" /><client type="PC" version="3.5.2540" platform="W5.1" /><servers version="0" /><service-no version="0" /><parameters version="0" /><hints version="0" /><http-applications version="0" /><client-config version="0" /></config>',@phone_num)
		headers = {
		  'Content-Type' => 'application/x-www-form-urlencoded'
		}
		resp = http.post(uri.path, params, headers)
		puts resp,resp.body
		return resp.body
	end
	
	def SSIAppSignIn(url)
		uri = URI.parse(url)
		path = uri.path + "?mobileno=" + @phone_num + "&pwd=" + @password
		http = Net::HTTP.new(uri.host,uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE # turn off SSL warning
		resp, xml = http.get(path, nil)
		puts resp,xml		
		ok = "200"
		doc = REXML::Document.new(xml)
		doc.elements.each("//results") do|element|
		   ok = element.attribute("status-code").value
	        end
	        if not @_count
			@_count = 0
		end
		if ok != "200" and @_count<3#421 verification picture?
		    	@_count = @_count+1
			return self.SSIAppSignIn(url)
	        end
	        return xml
	end
    
	def get_fetion_num(xml)
		@uri = ""
		doc = REXML::Document.new(xml)
		doc.elements.each("//results/user") do |element|
		  @uri = element.attribute("uri").value
		end	
		return @uri.scan(/sip:([0-9]+)@/)[0][0]
	end
end

class SIPC
	def initialize(sipc_addr)
		uri = sipc_addr.split(":")
		@socket = TCPSocket.new(uri[0], uri[1].to_i)
	end

	# send SIP request
	def request(sip_request)
		puts sip_request
		@socket.write_nonblock(sip_request)
		#select read_nonblock and rescue is the key
		IO.select [@socket]
		res = ""
		begin
			while chunk = @socket.read_nonblock(4096)
				res = res + chunk
			end
		rescue
		        puts "Error: #{$!}"
		end
		puts res 
		return res 
	end
end

#for test
if __FILE__ == $0
    fetion = Fetion.new("13651368727","my password")
    fetion.login()
    fetion.send_sms_to_self("test-ruby-fetion")
    #fetion.send_sms("mobileID","any sms")
end
