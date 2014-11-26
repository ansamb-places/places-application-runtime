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
protocol_name = 'fs'
module.exports = (options,imports,register)->
	content_lib = imports["api.place.content"]

	protocolHandler = (message)->
		#FIX: ignore "forwarded_to" message
		return if message.hasOwnProperty("forwarded_to")
		#dirty trick to test VOIP
		if message.method=="DOWNLOAD"
			code = message.code
			if code==200
				content_lib.handleDownloadEnd message.dpl,message.content_id,(err)->
					console.log "DOWNLOAD ERROR:",err if err?
		else if message.method=="UPLOAD"
			code = message.code
			if code==200
				content_lib.handleUploadEnd message.dpl,message.content_id,(err)->
					console.log "UPLOAD ERROR:",err if err?
		else
			console.error "Method #{message.method} of protocol #{protocol_name} is not supported"
	imports["protocol.handler"].registerProtocolHandler protocol_name,protocolHandler
	register null,{}