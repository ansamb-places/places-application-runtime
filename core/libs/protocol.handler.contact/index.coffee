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
protocol = "contact"
_ = require 'underscore'
messageHelper = require '../../common_lib/NetworkMessageHelper'

module.exports = (options,imports,register)->
	contact_lib = imports["api.contact"]
	avatar_manager = imports["avatar_manager"]
	protocolHandler = (message)->
		#receive a contact request from a peer (the user have to accept or not)
		if message.method=="ADD"
			if message.hasOwnProperty('ref_id')
				console.log "receive an add reply"
				#this is an ADD reply
				if message.code==200
					# if not _.isUndefined message.data.avatar
					# 	avatar_manager.createAvatarForUid message.src,message.data.avatar
					contact = message.data?.contact?.data
					contact_lib.updateContact message.src,{
						status:contact_lib.status.accepted
					},{conv_create:true},(err,contact_obj)->
						return console.error(err) if err?
						console.log "contact #{contact_obj.uid} has accepted your request"
				else if message.code==470
					contact_lib.deleteContactByUid message.data.src,(err,contact)->
						return console.error(err) if err?
			else
				data_field = message.data
				contact = data_field?.contact?.data
				if _.isUndefined(contact)
					console.log "Receive an invalid ADD CONTACT request"
					return
				contact_data =
					uid:message.src
					firstname:contact.firstname
					lastname:contact.lastname
					request_id:message.message_id
					status:'pending'
					message:data_field.message
				if contact.aliases
					aliases = messageHelper.aliasesDbArrayAdapter(contact.aliases,{first_as_default:true})
				else
					aliases = []
				options = 
					aliases:aliases
				contact_lib.addOrUpdateContact contact_data,options,(err,values)->
					console.error(err) if err?
		#one device have accepted a request
		# else if message.method=="CANCEL"
		# 	if message.code == 200
		# 		contact_lib.updateContact message.data.src,{status:contact_lib.status.accepted},(err,contact)->
		# 			return console.error(err) if err?
		# 	else if message.code == 470
		# 		contact_lib.deleteContactByUid message.data.src,(err,contact)->
		# 			return console.error(err) if err?
		#a contact have decided to be no more my friend
		else if message.method=="REMOVE"
			if message.hasOwnProperty('ref_id')
				return #we don't handle any remove reply here
			else
				contact_lib.removeContactByUid message.src,{emit_network:false,notify_ui:true},(err)->
					return console.error(err) if err?
		else if message.method=="STATUS"
			contact_lib.setContactsStatus message.data if message.data?
		else
			console.error "[Protocol #{protocol}]:unable to process message:",message
	imports["protocol.handler"].registerProtocolHandler 'contact',protocolHandler
	register null,{}