require 'rubygems'
require 'sinatra'
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
	"<pre style='border:solid 1px red;'>#{RBeautify.beautify_string(params['code'])[0]}</pre> #{HTML}"
end