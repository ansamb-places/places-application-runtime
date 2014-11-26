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
	'cs!./DataManager'
	'cs!backend_api/ContactBackendAPI'
],(Events,DataManager,ContactBackendAPI)->
	collection = DataManager.getContactCollection()
	Events.on 'contact:create',(contact)->
		collection.add contact
		ContactBackendAPI.syncStatus()
	Events.on 'contact:update',(uid,update)->
		collection.findWhere({uid:uid}).set(update)
	Events.on 'contact:delete',(uid)->
		collection.remove(collection.findWhere({uid:uid}))
	Events.on 'contact:status',(contacts)->
		_.each contacts, (state,uid)->
			model = collection.findWhere({uid:uid})
			model.set("state",state) if model?
	Events.on 'place:ready',(place)->
		if place.type=="conversation"
			contact= DataManager.getContactCollection().findWhere({conversation_id:place.id})
			contact.set "conversation_ready",true if contact?
			ContactBackendAPI.syncStatus()
	return null