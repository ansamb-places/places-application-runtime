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
async = require 'async'

###
this handler will just catch the incoming message and send it to the browser through the event helper
the browser will receive a socket.io event with the following name -> message:message
###
module.exports = (options,imports,register)->
	events = imports.events.namespaced("message")
	protocolHandler = (message)->
		if message.method=='PUT'
			payload = message.data
			src = message.src
			content_type = message.content_type
			events.emit content_type,src,payload
	imports["protocol.handler"].registerProtocolHandler 'message',protocolHandler
	register null,{}