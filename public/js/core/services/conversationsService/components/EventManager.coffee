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
define [
	'cs!modules/EventsManager'
	'cs!./ConversationManager'
	'cs!./Controller'
	'cs!../entities/Conversations'
	'cs!backend_api/PlaceBackendAPI'
	'cs!app'
],(Events,ConversationManager,Controller,Conversations,PlaceBackendAPI,App)->
	trackUploadEnd = (place_id,content_id)->
		conv= ConversationManager.getConversation(place_id)
		if conv
			if typeof(conv.collection.state_promises[content_id])=='undefined'
				conv.collection.state_promises[content_id]= $.Deferred() 
			conv.collection.state_promises[content_id].resolve('upload:end')
	trackDownloadEnd = (place_id,content_id)->
		conv= ConversationManager.getConversation(place_id)
		if conv
			conv.collection.state_promises[content_id]= $.Deferred() if !conv.collection.state_promises[content_id]
			conv.collection.state_promises[content_id].resolve('download:end')
	Events.on 'content:new',(place,content,read_ack)=>
		return if place.type!="conversation"
		conv = ConversationManager.getConversation(place.id)
		if conv
			read_ack true
			content.read = true
			conv.postFromKernel content
			place_model = Conversations.findWhere({id:place.id})
			if !place_model
				Conversations.fetch()
				return
			place_model.set 'last_content',content
			Conversations.trigger "last_content:changed",content
		else
			read_ack false
			place_model = Conversations.findWhere({id:place.id})
			if place_model
				place_model.set 'last_content',content
				Conversations.trigger "last_content:changed",content
			else
				place.last_content = content
				Conversations.add place
	Events.on 'download:end',trackDownloadEnd
	Events.on 'upload:end',trackUploadEnd
	Events.on 'ansamber:new',(place_id,ansamber)->
		conv = Conversations.findWhere({id:place_id})
		return if not conv?
		ansambers = conv.get('ansambers')
		if ansambers?
			ansambers.push(ansamber)
			conv.set('ansambers',ansambers)
		else conv.set('ansambers',[ansamber])
	Events.on 'content:read:update',(place_id,patch)->
		#TODO use the patch var to change correctly the notifications
		conv = Conversations.findWhere({id:place_id})
		return if not conv?
		last_content = conv.get('last_content')
		if patch["*"]?
			conv.set 'last_content.read',patch["*"].read if last_content?
		Conversations.trigger "last_content:changed",null
	Events.on 'place:new',(place)->
		if place.type=="conversation" and !Conversations.findWhere({id:place.id})
			# we have to manually retrieve the ansambers for the new place
			PlaceBackendAPI.getAnsambersForPlace(place.id).done (ansambers)->
				place.ansambers = ansambers
				Conversations.add place
			.fail (err)->
				if err?
					console.log "An error occured while trying to retrieve ansambers for place #{place.id}:",err
				Conversations.add place
	Events.on 'place:update',(place_id,update_patch)->
		model = Conversations.findWhere({id:place_id})
		model.set update_patch if model
	Events.on 'place:status:change',(place_id,new_status)->
		model = Conversations.findWhere({id:place_id})
		if model and model.get('status')!=new_status
			model.set('status',new_status)
	return null