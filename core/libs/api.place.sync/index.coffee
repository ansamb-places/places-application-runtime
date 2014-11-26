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
_when = require 'when'
async = require 'async'
_ = require 'underscore'
module.exports = (options,imports,register)->
	place_lib = imports["api.place"]
	protocol_builder = imports["protocol.builder"]
	server_link_mgmt = imports.server_link_management
	server = imports["server"]
	express_app = server.app

	api=
		# this array will contains some place_id to check for ready state after a sync is completed
		placeToCheckAfterSync:[]

		enableDisableSyncForPlace:(place_id,action,options)->
			if _.isUndefined(options) or options == null
				options = {}
			_.defaults options,{reset:false}
			# check if this place have all basics documents or not
			if not _.has(@placeToCheckAfterSync,place_id)
				place_lib.getPlace place_id,(err,place)=>
					if err == null and place? and not place.isNetworkSynced()
						@placeToCheckAfterSync[place_id] =
							place:place_id
							owner:place.owner_uid
			return _when.promise (resolve,reject)->
				switch action
					when "enable"
						protocol_builder.sync.enableSyncForPlace
							place_id:place_id
							channel:'default'
							reset:options.reset
						.send()
						resolve()
					when "disable"
						protocol_builder.sync.disableSyncForPlace
							place_id:place_id
						.send()
						resolve()
					else
						reject "Incorrect sync action"
		enableDisableAutoSyncForPlace:(place_id,action,cb)->
			async.waterfall [
				(callback)->
					place_lib.getPlace place_id,callback 
				(place,callback)->
					return callback "place not found" if place == null
					return callback "place is disabled" if place.status == "disabled"
					api.enableDisableSyncForPlace(place_id,action).done (err)->
						callback err,place
				(place,callback)->
					switch action 
						when "enable"
							place.auto_sync = true
							place.last_sync_date= null
						when "disable"
							place.auto_sync = false
							place.last_sync_date= new Date()
						else
							callback "Incorrect sync action"
					place.save().done callback
			],(err,place)->
				if err == null
					cb null,place.last_sync_date
				else 
					cb err,null
		# this method will try to enable sync for all place where the sync is enabled
		enableSyncForAllPlace:(cb)->
			async.waterfall [
				(callback)->
					place_lib.getAllPlaceWithSyncEnabled {raw:true},callback
				(places,callback)->
					return callback(null) if places == null
					_.each places,(place)->
						protocol_builder.sync.enableSyncForPlace
							place_id:place.id
							channel:'default'
						.send()
					callback null
			],(err)->
				cb and cb err

	########################### HTTP API ##################################
	prefix = "#{server.url_prefix.core_api}/sync"

	express_app.get "#{prefix}/:place/:action",(req,res)->
		place_id = req.param("place")
		action = req.param("action")
		reset = req.query.reset
		if reset == "1" or reset == "true"
			reset = true
		api.enableDisableSyncForPlace(place_id,action,{reset:reset})
		.done ->
			res.send {err:null,ok:true}
		,(error)->
			res.send {err:error,ok:false}

	express_app.get "#{prefix}/auto/:place/:action",(req,res)->
		place_id = req.param("place")
		action = req.param("action")
		api.enableDisableAutoSyncForPlace place_id,action,(err,last_sync_date)->
			res.send {err:err,last_sync_date:last_sync_date}

	### Dynamic SYNC behaviour ### 
	place_lib.on "place:ready",(place)->
		if place.auto_sync
			protocol_builder.sync.enableSyncForPlace
				place_id:place.id
				channel:'default'
			.send()

	server_link_mgmt.on "status:change",->
		if server_link_mgmt.isLinkConnected()
			api.enableSyncForAllPlace()

	register null,{"api.place.sync":api}
