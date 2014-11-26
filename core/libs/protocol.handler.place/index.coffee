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
async = require 'async'
_ = require 'underscore'
protocol = "place"

is_a_reply = (message)->
	return message.hasOwnProperty('ref_id')

module.exports = (options,imports,register)->
	place_lib = imports["api.place"]
	ansamber_lib = imports["api.place.ansamber"]
	account_lib = imports["api.account"]
	events = imports["events"]
	protocol_builder = imports["protocol.builder"]
	api_place_sync = imports["api.place.sync"]

	protocolHandler = (message)->
		#receive a contact request from a peer (the user have to accept it or not)
		if message.method=="ADD_ANSAMBER"
			if is_a_reply(message)
				console.log "receive an add_ansamber reply"
				place_id = message.dpl
				uid = message.src
				#this is an ADD reply
				if message.code==200
					ansamber_lib.changeAnsamberStatus place_id,uid,ansamber_lib.status.accepted,(err,ansamber)->
						return console.error(err) if err?
						console.log "ansamber #{ansamber.uid} validated"
				else if message.code==470 or message.code==403
					options = {notify_ui:true,emit_network:false,code:message.code}
					ansamber_lib.removeAnsamberFromPlace place_id,uid,options,(err,contact)->
						return console.error(err) if err?
			else
				owner_uid = message.data.owner_uid
				if owner_uid==null or _.isUndefined(owner_uid) or owner_uid==''
					return console.error("Illegal place creation (no owner uid defined)")
				place_data = message.data
				# apply a special status in this case
				if _.has(place_data,'access_mode') and (forceNextStatus=place_lib.accessModeAdapter(place_data.access_mode))?
					# place status semantic: currentStatus:statusAfterValidated
					place_status = "#{place_lib.status.pending}:#{forceNextStatus}"
				else
					place_status = place_lib.status.pending
				place = 
					id:place_data.uid
					name:place_data.name||""
					desc:place_data.desc||""
					type:place_data.type
					owner_uid:owner_uid
					creation_date:new Date(place_data.creation_date)
					add_request_id:message.message_id
					status:place_status
				auto_validate = if place_data.type=="conversation" then true else false
				handlePlaceAdd = ->
					place_lib.addOrUpdatePlace place,{db:{raw:true},auto_validate:auto_validate},(err,p)->
						return console.error(err.message) if err?
						ansamber_option = 
							admin:true
							request_id:message.message_id
							status:"validated"
						console.log "ADDING ANSAMBER TO PLACE #{p.id}"
						ansamber_lib._addAnsamber p.id,message.src,ansamber_option,(err)->
							console.error(err) if err?
				if auto_validate == true
					# delay the management of the add to be sure that noyo is ready to receive
					# next network messages (ensure that all required documents have been created)
					setTimeout handlePlaceAdd,3000
				else
					handlePlaceAdd()
		else if message.method == "REMOVE_ANSAMBER"
			return if message.ref_id
			uid = message?.data?.uid
			return console.log "Uid missing from the REMOVE_ANSAMBER message" if _.isUndefined uid
			account_lib.getUidAsync (err,my_uid)->
				return console.log "No UID defined" if err? or _.isUndefined my_uid
				#disable the place if the ansamber who is removed from the place is myself
				if my_uid == uid
					place_lib.disablePlace message.dpl,(err)->
						console.log err if err?
				else
					ansamber_lib.removeAnsamberFromPlace message.dpl,uid,{emit_network:false,notify_ui:true},(err)->
		else if message.method == "CREATE"
			place_id = message?.data?.uid ? null
			place_lib._kernelValidatePlace place_id,message.code==200,message.data
		else if message.method == "RENAME"
			options =
				new_name:message.data.name
				check_name:false
				emit_network:false
			place_lib.renamePlace message.dpl,options,(err,old_place,updated_attr)->
				console.log err if err?
		else if message.method == "DELETE"
			#reply to requests is not the business of the protocol handler
			return if is_a_reply(message)
			place_lib.disablePlace message.dpl,(err)->
				console.log err if err?
		else if message.method == "GET_BASICS"
			code = message.code
			place_id = message.spl
			switch code
				when 200,202
					delete api_place_sync.placeToCheckAfterSync[place_id]
				when 204
					place_lib._kernelValidatePlace message.spl,true,{}
					delete api_place_sync.placeToCheckAfterSync[place_id]
				when 403,404
					console.error message.desc||'Error'
		else
			console.error "Method #{message.method} of protocol #{protocol} is not supported"
	imports["protocol.handler"].registerProtocolHandler protocol,protocolHandler
	register null,{}
