###
	Places, Copyright 2014 Ansamb.
	
	This file is part of Places By Ansamb.
	
	Places By Ansamb is free software: you can redistribute it and/or modify it
	under the terms of the Affero GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.
	
	Places By Ansamb is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
	or FITNESS FOR A PARTICULAR PURPOSE. See the Affero GNU General Public
	License for more details.
	
	You should have received a copy of the Affero GNU General Public License
	along with Places By Ansamb. If not, see <http://www.gnu.org/licenses/>.

###
_ = require 'underscore'
request = require 'request'
module.exports =
	protocol:"HTTP"
	request:(uri,method,args,options,cb)->
		if _.isUndefined(cb)
			cb = options
			options = {}
		#TODO check all args are here
		req_options =
			uri:uri
			method:method
			strictSSL:false
		if _.isObject(options.auth)
			req_options.auth =
				user:options.auth?.login
				pass:options.auth?.password
				sendImmediately:true
		switch method
			when "GET"
				req_options.qs = args
			when "POST"
				req_options.json = args
		request req_options,(error,httpMessage,reply)->
			return cb error.message||error if error?
			if _.isUndefined(httpMessage) or httpMessage == null
				return cb "Request error (got no reply)"
			result = {http_code:httpMessage.statusCode}
			if Math.floor(httpMessage.statusCode/100)==2
				try
					if typeof reply == "string" and reply.length > 0
						reply = JSON.parse(reply)
						result = _.extend reply,result
				catch e
					return cb "Invalid JSON reply",result
			else if httpMessage.statusCode == 401
				return cb "Unauthorized",result
			else
				return cb "Request error (code #{httpMessage.statusCode})",result
			return cb null,result