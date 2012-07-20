require 'rubygems'
require 'sinatra'
$LOAD_PATH.unshift(File.dirname(__FILE__)) 
require 'beautify'

HTML = "beautify ruby source code:
	<form action='/beautify' method='post'>
		<textarea name='code' style='width:80%;height:50%;'></textarea>
		<input type='submit' value='beautify'/>
	</form>"

get '/' do 
	HTML
end

post '/beautify' do 
	"<textarea style='border:solid 1px red;width:80%;height:50%;'>#{RBeautify.beautify_string(params['code'])[0]}</textarea> #{HTML}"
end