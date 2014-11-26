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
util = require 'util'
protocol_name = 'sync'
module.exports = (options,imports,register)->
	protocol_builder = imports["protocol.builder"]
	document_broker = imports["document.network.broker"]
	api_place_sync = imports["api.place.sync"]

	# private utils functions
	getField=(arr,format,field_name)->
		return arr[format.indexOf(field_name)]
	checkIfContainsBasicsDocuments = (refs,format)->
		checkType = 
			key: false
			ansamber: false
			place_settings: false
		_.each refs,(ref)->
			contentType = getField(ref,format,'content_type') || null
			checkType[contentType] = true if _.has(checkType,contentType)
		ok = true
		_.each checkType,(exists)->ok = ok && exists
		return ok

	protocolHandler = (message)->
		switch message.method
			when "NEW_UPDATES"
				refs = message.data.updates
				format = message.data.updates_format
				place_id = message.spl
				# check if a get_basics message is required
				if api_place_sync.placeToCheckAfterSync.hasOwnProperty(place_id) and not checkIfContainsBasicsDocuments(refs,format)
					protocol_builder.place.getBasicsDocuments(api_place_sync.placeToCheckAfterSync[place_id]).send()
				_.each refs,(ref)->
					protocol_builder.sync.get
						place_id:message.spl
						content_id:getField(ref,format,'content_id')
					.send (err,reply)->
						# if the code is 204, we don't handle the doc because it's not the last content revision
						# the case could be encoutered for contents which have been deleted or removed
						if reply.code == 200
							# TODO content can contain multiple version of the doc
							doc = reply.data.content
							# console.log util.inspect(reply,{depth:null})
							return document_broker.handleDocument(protocol_name,message.method,doc)

			else
				console.error "Can't handle method #{message.method} of protocol SYNC"
	imports["protocol.handler"].registerProtocolHandler protocol_name,protocolHandler
	register null,{}