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
	'cs!modules/EventsManager',
	'cs!./DataManager',
	'cs!app'
],(EventsManager,DataManager,App)->

	#TODO use only this var as current place id and not one for each events
	current_place_id = null

	# tracking functions
	_collection = null
	_place_id = null
	trackContent = (event_place,content,read_ack)->
		#update read place badge
		place = DataManager.getPlaceCollection().findWhere({id:event_place.id})
		if _place_id == event_place.id
			content.new=true if _.isUndefined(content.read)
			_collection.add(content) if _collection
			read_ack false #to do nothing backend side about read field
		place.incrementBadge() if place
		App.vent.trigger 'system:notify' # affect also conversation messages
		
	trackContentUpdate = (event_place,content,read_ack)->
		return if _collection==null or _place_id == null
		place = DataManager.getPlaceCollection().findWhere({id:event_place.id})
		if _place_id == event_place.id
			content.new=true if _.isUndefined(content.read)
			model = _collection.findWhere({id:content.id})
			model.set(content) if model?
			read_ack false if read_ack
		place.incrementBadge()
		
	trackContentRename = (place_id,old_content_id,options)->
		return if _collection==null or _place_id == null
		if _place_id == place_id
			new_name = options.name
			relative_path = options.relative_path
			new_content_id = options.new_content_id
			model = _collection.findWhere({id:old_content_id})
			model.set {'id':new_content_id,'data.name':new_name,'data.relative_path':relative_path} if model?
	trackContentDelete = (event_place,content_id)->
		return if _collection==null or _place_id == null
		if _place_id == event_place.id
			_collection.remove(_collection.findWhere({id:content_id}))

	_collection_ansamber = null
	_place_id_ansamber = null
	trackNewAnsamber = (place_id,ansamber)->
		return if _collection_ansamber==null or _place_id_ansamber==null
		if place_id == _place_id_ansamber
			_collection_ansamber.add(ansamber)	

	trackExistingAnsamber =(place_id,ansamber)->
		return if _collection_ansamber==null or _place_id_ansamber==null
		if place_id == _place_id_ansamber
			existingAnsamber = _collection_ansamber.findWhere({uid:ansamber.uid})
			if existingAnsamber != null and typeof existingAnsamber != "undefined"
				existingAnsamber.set(ansamber)
	trackRemovedAnsamber =(place_id,ansamber_uid,message)->
		return if _collection_ansamber==null or _place_id_ansamber==null
		if place_id == _place_id_ansamber
			ansamber = _collection_ansamber.findWhere({uid:ansamber_uid})
			_collection_ansamber.remove(ansamber) if ansamber
			alert message if message
	trackDownloadEnd = (place_id,content_id)->
		return if _collection==null or _place_id==null
		if _place_id==place_id
			_collection.state_promises[content_id]= $.Deferred() if !_collection.state_promises[content_id]
			_collection.state_promises[content_id].resolve('download:end')
				
	trackUploadEnd = (place_id,content_id)->
		return if _collection==null or _place_id==null
		if _place_id==place_id
			if !_collection.state_promises[content_id]
				_collection.state_promises[content_id]= $.Deferred() 
			_collection.state_promises[content_id].resolve('upload:end')

	EventsManager.on 'place:ready',(place)->
		if place.type=="share"
			p = DataManager.getPlaceCollection().findWhere({id:place.id})
			if p?
				p.set place
			else
				DataManager.getPlaceCollection().add place

	EventsManager.on 'place:new',(place)->
		if place.type=="share"
			DataManager.getPlaceCollection().add place
	EventsManager.on 'place:update',(place_id,update_patch)->
		model = DataManager.getPlaceCollection().findWhere({id:place_id})
		model.set update_patch if model
	EventsManager.on 'place:status:change',(place_id,new_status)->
		model = DataManager.getPlaceCollection().findWhere({id:place_id})
		if model and model.get('status')!=new_status
			model.set('status',new_status)

	EventsManager.on 'ansamber:new',trackNewAnsamber
	EventsManager.on 'ansamber:update',trackExistingAnsamber
	EventsManager.on 'ansamber:remove',trackRemovedAnsamber
	EventsManager.on 'content:new',trackContent
	EventsManager.on 'content:delete',trackContentDelete
	EventsManager.on 'content:update',trackContentUpdate
	EventsManager.on 'content:rename',trackContentRename
	EventsManager.on 'download:end',trackDownloadEnd
	EventsManager.on 'upload:end',trackUploadEnd

	App.vent.on "place:current",(place_id)->
		current_place_id = place_id

	return {
		setTrackAnsamber:(collection,place_id)->
			# EventsManager.removeListener e1,trackNewAnsamber
			# EventsManager.removeListener e2,trackExistingAnsamber

			_collection_ansamber = collection
			_place_id_ansamber = place_id
			
		setTrackedContent:(collection,place_id)->

			# EventsManager.removeListener e,trackContent
			_collection = collection
			_place_id = place_id
	}