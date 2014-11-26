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
protocol_name = 'content'
module.exports = (options,imports,register)->
	document_broker = imports["document.network.broker"]
	content_lib = imports["api.place.content"]

	mergeData = (doc)->
		#TODO remove this ugly thing
		doc.data = null if doc.data=="undefined"
		doc.data = doc.data||{}
		_.extend doc.data,doc.clear_data

	protocolHandler = (message)->
		mergeData(message)
		#FIX: ignore "forwarded_to" message
		return if message.hasOwnProperty("forwarded_to")
		#dirty trick to test VOIP
		if message.method=="PUT" and message.content_type=="voip"
			return imports.events.namespaced("transport").emit "message",message.src,message.data
		if message.method=="PUT"
			document_broker.handleDocument(protocol_name,message.method,message)
		else if message.method=="SEND"
			doc = message.data.content
			document_broker.handleDocument protocol_name,message.method,doc
		else if message.method=="DELETE"
			content_lib._deleteContentOfPlace message.dpl,{id:message.content_id,emit_network:false},(err,deleted)->
				console.log err if err?
				#TODO manage errors
		else if message.method=="RENAME"
			options =
				old_content_id:message.content_id
				new_content_id:message.data.new_content_id
				new_name:message.data.name
				new_relative_path:message.data.relative_path
				new_rev:message.data.rev
				content_type:message.content_type
				emit_network:false
			content_lib.renameFileContent message.dpl,options,(err)->
				console.log err if err?
		else
			console.error "Method #{message.method} of protocol content is not supported"
	imports["protocol.handler"].registerProtocolHandler protocol_name,protocolHandler
	register null,{}