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
mkdirp = require 'mkdirp'
path = require 'path'
uuid = require 'node-uuid'
async = require 'async'
_ = require 'underscore'
_when = require 'when'
rimraf = require 'rimraf'
fs = require 'fs'
EventEmitter = require('eventemitter2').EventEmitter2
require_place_name = require("../../common_lib/express_middlewares").require_place_name
require_place_id = require("../../common_lib/express_middlewares").require_place_id
require_ansamber_id = require("../../common_lib/express_middlewares").require_ansamber_id
require_field_id = require("../../common_lib/express_middlewares").require_field_id
require_field_type = require("../../common_lib/express_middlewares").require_field_type
require_field_name = require("../../common_lib/express_middlewares").require_field_name
utils = require '../../common_lib/utils'
# routes = require ('./routes')

# routes app, express;

i=0
errors = 
	place_exists:
		code:i++
		message:'Place already exists'
	place_not_found:
		code:i++
		message:'Place not found'
	orm_error:
		code:i++
		message:'SQLITE error'
	peer_user_place_missing:
		code:i++
		message:'Peer user place is missing'
###
	when the place has no owner, the owner is the current user
###
module.exports = (options,imports,register)->
	global_options = options
	db = imports.database_manager
	account_lib = imports["api.account"]
	server = imports.server
	express = server.app
	events = imports["events"].namespaced("place")
	protocol_builder = imports["protocol.builder"]
	ansamber_lib = imports["api.place.ansamber"]
	notification_manager = imports["notification_manager"]
	application_registery = imports["application.registery"]
	file_dir = options.file_dir
	local_cache = {}

	getMainDatabase = (cb)->
		db.getApplicationDatabase cb
	#API definition
	api = new EventEmitter
	_.extend api,
		status:
			pending:'pending'
			later:'later'
			validated:'validated'
			disabled:'disabled'
			readonly:'readonly'
			to_be_sync:'to_be_sync'
		accessModeAdapter:(accessMode)->
			if accessMode == 1
				return "readonly"
			else
				return null
		sync_status:
			'none':0
			'kernel_only':1
			'fully':2
		getAllPlace:(filter,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {raw:false}

			filter = filter||{}
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(db,callback)->
					db.models.global.place.__places__.getAll({where:filter}).done callback
				(_places,_callback)->
					if options.ansambers==true
						async.map _places,(item,callback)->
							res = item.values
							res.ansambers = []
							item.getAnsambers({raw:true}).done (err,ansambers)->
								res.ansambers = ansambers if ansambers?
								callback err,res
						,_callback
					else
						return _callback null,_.map(_places,(item)->item.values)
			],cb
		getAllPlaceWithSyncEnabled:(options,cb)->
			if _.isUndefined cb
				cb = options
				options = {raw:false}
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(db,callback)->
					filter = {status:[api.status.validated,api.status.readonly],auto_sync:true}
					db.models.global.place.__places__.getAll({where:filter,options:options}).done callback
			],cb
		addPlace:(place_data,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			#default place options
			place_data = _.extend
				creation_date:new Date
				status:api.status.pending
			,place_data
			#default options
			options = _.extend
				db:{raw:true}
				auto_validate:false
				wait_validation:false #to wait kernel reply to call the callback
			,options
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					checkPlace = (err,place)->
						if err?
							console.log err
							return callback errors.orm_error
						if place?
							return callback errors.place_exists
						callback null,main_db
					#if the owner is the current user, we have to check if the place name is a new one
					if place_data.owner_uid == null
						main_db.models.global.place.find({where:{name:place_data.name}}).done checkPlace
					#in this case, the place has been created by someone else, just check if the id is unique
					else
						main_db.models.global.place.__places__.getByid(place_data.id).done checkPlace
				(main_db,callback)->
					main_db.models.global.place.create(place_data).done callback
				(place,callback)->
					db.createDatabaseForPlace place.id,(err)->
						callback err,place
				(place,callback)->
					#also auto validate if we are the owner
					if options.auto_validate==true or place.owner_uid==null or place_data.status == api.status.to_be_sync
						if place_data.status == api.status.to_be_sync
							status = api.status.to_be_sync
						else 
							status = if options.auto_validate == true then api.status.validated else place_data.status
						api._changePlaceStatus place.id,{status:status},place,callback
					else
						callback null,place
			],(err,place)->
				if err==null
					console.log "place saved"
					createNotification = (place,owner)->
						if place.type=="share"
							#if the place is created by someone else, the notification is created
							#with a global scope to use have it appeared also into the notification manager
							scope = if place.owner_uid? then "*" else "dashboard"
							tag = if place.owner_uid? then "place:request" else "place:new"
							notif_data = {
								name:place.name
								type:place.type
								owner_uid:place.owner_uid
								creation_date:place.creation_date
							}
							if place.owner_uid?
								notif_data.firstname = owner.firstname if owner and owner.firstname
								notif_data.lastname = owner.lastname if owner and owner.lastname
							notification_manager.createNotification null,place.id,notif_data,tag,scope,place.owner_uid?,true
					place_return = if options.db.raw==true then place.values else place
					place.getOwner().done (err,owner)->
						createNotification place,owner
						place_return.owner= if options.db.raw==true and owner then owner.values else owner
						events.emit 'new',place_return
					api.emit 'place:new',place_return,api.generateFolderName(place.name,place.owner_uid)
					if options.wait_validation==true
						api.once "place:ready:#{place.id}",->
							cb null,place_return
					else cb(null,place_return)
				else
					cb(err,null)
		# this methods is called by proto handler when a place is synced with the kernel
		# an event will be emitted to notify the UI and other core components
		# @ready define if the place is ready (so we can put documents in the place) or not
		# options will have some missing informations about the place (creation_date, ...)
		_kernelValidatePlace:(place_id,ready,options)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.place.find({where:{id:place_id},include: [{model:main_db.models.global.ansamber,as:'owner'}]}).done callback
				(place,callback)->
					return callback "Place not found" if place==null
					if place.network_synced == api.sync_status.none
						#create required directories
						apps = application_registery.getApplicationsWithStorage()
						_.each apps,(app_name)->
							mkdirp.sync path.join(file_dir,app_name,api.generateFolderNameSync(place))
					callback null,place
				(place,callback)->
					if place.network_synced == api.sync_status.none
						creation_date = new Date(options.creation_date)
						# if date.toJSON is null, it means that the date is not a valid one
						if creation_date.toJSON() != null
							place.creation_date = creation_date
					if ready == false
						place.network_synced = api.sync_status.kernel_only
					else
						place.network_synced = api.sync_status.fully
					place.save().done (err)->
						callback err,place
			],(err,place)->
				return console.log err if err?
				if ready == true
					place_values = place.values
					place_values.owner = place.owner.values if place.owner
					events.emit 'ready',place_values
					api.emit "place:ready",place_values
					api.emit "place:ready:#{place_values.id}"
		#place_object allow to bypass the find step in using an already existing orm object
		#options = {status:string,request_id:string|null}
		_changePlaceStatus:(place_id,options,place_object,cb)->
			if _.isUndefined cb
				cb = place_object
				place_object = null
			status = options.status || null
			add_request_id = options.add_request_id || null
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					return callback null,place_object if place_object?
					main_db.models.global.place.find({where:{id:place_id}}).done callback
				(place,callback)->
					return callback "Place not found",false if place==null
					# return callback null,false,place if place.status==status
					regexp= /:(.*)/
					result= regexp.exec(place.status)
					if result and status== api.status.validated
						place.status= result[1] 
					else
						place.status= status
					net_object = null
					if status==api.status.validated or status==api.status.to_be_sync
						#notify the kernel about the new place
						place_create_object =
							owner_uid : place.owner_uid||account_lib.getUid()
							id : utils.parsePlaceId(place.id)?.uuid
							uid : place.id #the uid is the complete place reference (ID@owner)
							creation_date : +new Date(place.creation_date)
						pick_values = ['name','desc','type']
						place_create_object = _.extend place_create_object,_.pick(place.values,pick_values)
						net_object = protocol_builder.place.placeCreateRequest place_create_object
						place.network_request_id = net_object.getMessageId()
					place.save().done (err)->
						net_object.send() if net_object?
						#if we are not the owner, notify the user that we've accepted his request
						if place.owner_uid? and status==api.status.validated
							protocol_builder.place.addAnsamberReply({
								place:place.id
								user_uid:place.owner_uid
								request_id:add_request_id || place.add_request_id
								accepted:true
							}).send (err,reply)->
								if reply.code!=202
									#TODO manage errors
									console.error("Got a non-202 reply (#{reply.code}")
						callback err,true,place
			],(err,changed,place)->
				cb err,place
				#if place_object is not null, we don't have to emit event as the model is not yet present on the client
				events.emit "status:change",place_id,status if changed
		#this method have to be used by the kernel to create a place
		#Do not use addPlace because the request can target a disabled place so an already existed one
		addOrUpdatePlace:(place_data,options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {}
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.place.find({where:{id:place_data.id}}).done callback
				(place,callback)->
					if place == null
						api.addPlace place_data,options,callback
					else
						if options.auto_validate == true 
							status = api.status.validated 
						else 
							status = place_data.status ? api.status.pending
						if place.add_request_id != place_data.add_request_id
							place.set('add_request_id',place_data.add_request_id)
						options = {status:status,add_request_id:place_data.add_request_id}
						api._changePlaceStatus place_data.id,options,place,callback
			],cb
		_generateUniquePlaceId:(uid,place_options)->
			#generate a unique name in a deterministic way
			luid = ""
			ruid = ""
			owner_uid= null
			#TODO validate uuid format
			user_uid = account_lib.getUid()
			if user_uid<uid
				luid = user_uid
				ruid = uid
				owner_uid = null #the user is the owner
			else
				luid = uid
				ruid = user_uid
				owner_uid = uid
			type = place_options?.type||'conversation'
			place_uid = "#{luid},#{ruid}" #we need this specific part to send ansamber request
			place_id = @createPlaceId(type,place_uid,owner_uid).place_id
			return {place_id:place_id,place_uid:place_uid,luid:luid,ruid:ruid,type:type,owner_uid:owner_uid}
		#@ansamber_list allow to define a list of users who will be added as ansambers
		createRandomPlace:(type,ansamber_list,cb)->
			if _.isUndefined cb
				cb = ansamber_list
				ansamber_list = null
			owner_uid = account_lib.getUid()
			place_ids = @createPlaceId type,null,owner_uid
			place_data = 
				id:place_ids.place_id
				name:place_ids.place_uid
				type:type
				desc:"random place"
				owner_uid:null
			options =
				auto_validate:true
			api.addPlace place_data, options, (err,place)->
				return cb err,null if err?
				if not _.isUndefined(ansamber_list) and ansamber_list?
					ansamber_list = [ansamber_list] if not _.isArray(ansamber_list)
					async.each ansamber_list,(ansamber,callback)->
						ansamber_lib.addAnsamberToPlace id,ansamber,{admin:true,status:'validated'},callback
					,(error)->
						cb error,place
				else
					cb null,place
		#this function will return the unique place only shared with the given contact if exists
		getUniquePlaceWithContact:(uid,place_options,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			options= _.extend {raw:true},options
			place_info = @_generateUniquePlaceId(uid,place_options)
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.place.find({where:{id:place_info.place_id}}).done (err,place)->
						return callback errors.orm_error if err?
						callback err,place
				(place,callback)->
					if place?
						_place=place
						_place = place.values if options.raw
						if options.ansambers==true
							place.getAnsambers({raw:true}).done (err,ansambers)->
								_place.ansambers = ansambers if ansambers?
								return callback null,_place
						else
							return callback null,_place
					else
						return callback "Place not found",null
			],cb
		createUniquePlaceWithContact:(uid,place_options,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			place_info = @_generateUniquePlaceId(uid,place_options)

			# don't create the conv place if an options explicitely say no
			# this case is required to not create the place when we got an ADD contact reply
			# and we are not the owner
			if place_info.owner_uid != null and options.conv_create == false
				return cb(null,null)

			# QUICK FIX:
			# we create the place even if it's not our responsability 
			# to be able to put contents whenever we want
			status = if place_info.owner_uid == null then api.status.pending else api.status.to_be_sync
			# -------------------------------------------------------
			# the place have to be created by the peer in this case
			# if place_info.owner_uid!=null
			# 	return cb(null,null)
			place_data = _.extend {
				name:place_info.place_uid
				desc:"unique #{place_info.type} place between #{place_info.luid} and #{place_info.ruid}"
				type:place_info.type
				owner_uid:place_info.owner_uid
				status:status
			},place_options
			place_data.id = place_info.place_id
			async.waterfall [
				(callback)->
					auto_validate = if place_info.owner_uid == null then true else false
					api.addOrUpdatePlace place_data,{db:{raw:false},auto_validate:auto_validate},callback
				(place,callback)->
					if place_info.owner_uid == null
						ansamber_lib.addAnsamberToPlace place.id,uid,{
							admin:true
							status:'validated'
						},(ansamber_err,ansamber_created)->
							return console.error(ansamber_err) if ansamber_err?
							callback ansamber_err,place
					else
						# ansamber will be added later by the place protocol handler
						# if we are not the owner
						callback null,place
				(place,callback)->
					_place = place.toJSON()
					if options.ansambers==true
						place.getAnsambers({raw:true}).done (err,ansambers)->
							_place.ansambers = ansambers if ansambers?
							callback null,_place
					else
						callback null,_place
			],cb
		deleteAllPlace:(cb)->
			deletePlaceAdapter = (place,callback)=>
				@deletePlaceById place.id,callback
			getMainDatabase (err,db)->
				db.models.global.place.findAll({where:{type:"share"}}).done (err,places)->
					return cb(err) if err?
					async.each places,deletePlaceAdapter,(err)->
						cb err,places.length
		_deletePlaceFromDatabase:(id,cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.place.destroy({id:id}).done (err)->callback err
			],cb
		deletePlaceById:(id,options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {}
			place_folder = null
			async.waterfall [
				(callback)->
					getMainDatabase callback 
				(main_db,callback)->
					if options?.place_object?
						callback null,options.place_object
					else
						api.getPlace id,callback
				(place,callback)->
					if place.owner_uid == null
						protocol_builder.place.deletePlace({place:id}).send callback
					else
						protocol_builder.place.leavePlace({place:id}).send callback
				(reply,callback)->
					if reply.code != 200
						callback reply.desc||"Unknown error"
					else
						callback null
				(callback)->
					api.generateFolderNameFromPlaceId id,(err,folder_name)->
						if typeof folder_name=="string"
							place_folder = folder_name
							callback null
						else
							callback err
				(callback)->
					api._deletePlaceFromDatabase id,callback
				(callback)->
					apps = _.values(application_registery.getApplications())
					async.each apps,(app,_callback)->
						return _callback null if app?.file_storage != true
						p = path.join app.file_dir_path,place_folder
						rimraf p,_callback
					,(err)->
						console.log err if err?
						#we don't throw the error if something was wrong on file delete
						callback null
				(callback)->
					db.deleteDatabaseForPlace id,callback
			],(err)->
				if err==null
					delete local_cache[id] if local_cache[id]
					# we need to emit this event in order to make others components able to react and
					# perform special operations like cache update ...
					api.emit 'place:delete',id 
				cb err,err==null
		#this method will set a place as "disabled"
		#DISABLED means that the place will be accessible but no network activity will be possible within the place
		disablePlace:(id,options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {}
			options = _.extend {emit_network:false,notify_ui:true},options
			async.waterfall [
				(callback)->
					if options.emit_network == true
						protocol_builder.place.leavePlace({place:id}).send (err,reply)->
							return callback err if err?
							if reply.code != 200
								callback reply.desc||"Unknown error"
							else
								callback null
					else
						callback null
				(callback)->
					api.updatePlaceSettings {uid:id,status:api.status.disabled},(err,place_id,old_place,updated_attr)->
						if err==null
							scope = if old_place.type == "conversation" then "dashboard" else "*"
							notification_manager.createNotification place_id,place_id,{
								place_name:old_place.name
								type:old_place.type
								owner_uid:old_place.owner_uid
							},"place:disable",scope,options.notify_ui,true
						callback err
			],(err)->
				_.isFunction(cb) and cb err

		updatePlaceHumanAttributes: (place_id, newAttrs, options, cb) ->
			if _.isUndefined cb
				cb = options
				options = {}
			
			notify_ui = options.notify_ui ? true
			async.waterfall [
				(callback)->
					return callback "Invalid place id" if typeof place_id != "string"
					api.getPlace place_id,{raw:false},(err,place)->
						callback err,place
				(place,callback)->
					if newAttrs.name and newAttrs.name isnt place.name
						api.renamePlace place_id,{new_name : newAttrs.name}, (err) ->
							err = err.message() if err?.message
							callback err, place
					else 
						callback null, place
				(place, callback) ->
					black_list = ["id","type","status","owner_uid","creation_date"]
					update_patch = _.omit newAttrs,black_list
					old_place = _.clone(place.values)
					place.updateAttributes(update_patch,_.keys(update_patch)).done (err,data)->
						callback err,place_id,old_place,update_patch, data
				],(err,place_id,old_place,update_patch, data)->
					events.emit "update",place_id,update_patch if err==null and notify_ui==true
					cb err, data

		updatePlaceSettings:(new_settings,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			place_id = new_settings.uid
			notify_ui = options.notify_ui ? true
			if new_settings.access_mode and (new_status=api.accessModeAdapter(new_settings.access_mode))?
				new_settings.status = new_status
				delete new_settings.access_mode
			async.waterfall [
				(callback)->
					return callback "Invalid place id" if typeof place_id != "string"
					api.getPlace place_id,{raw:false},(err,place)->
						callback err,place
				(place,callback)->
					black_list = ["id","creation_date","owner_uid","uid"]
					update_patch = _.omit new_settings,black_list
					old_place = _.clone(place.values)
					place.updateAttributes(update_patch,_.keys(update_patch)).done (err)->
						callback err,place_id,old_place,update_patch
			],(err,place_id,old_place,update_patch)->
				events.emit "update",place_id,update_patch if err==null and notify_ui==true
				cb err,place_id,old_place,update_patch
		renamePlace:(place_id,options,cb)->
			new_name = options.new_name
			check_name = options.check_name ? true
			emit_network = options.emit_network ? true
			return cb "Invalid name" if typeof new_name!="string" or new_name==""
			async.waterfall [
				(callback)->
					if check_name == true
						#check if the new name not already exists
						api.getPlaceFromName new_name,{owner_uid:null},(err,place)->
							if place?
								callback "A place with this name already exists"
							else
								callback null
					else callback null
				(callback)->
					if emit_network == true
						protocol_builder.place.renamePlace
							place:place_id
							name:new_name
						.send (err,reply)->
							return callback err if err?
							code = reply.code
							if code == 200
								callback null
							else
								message = "Unkown error"
								#TODO manage protocol error messages into protocol builders
								switch code
									when 403 then message= "Renamed not allowed"
									when 404 then message= "Place not found"
									when 500 then message= "Malformed request"
								callback message
					else
						callback null
				(callback)->
					api.updatePlaceSettings {uid:place_id,name:new_name},{notify_ui:!emit_network},(err,place_id,old_place,updated_attr)->
						if err == null
							scope = if emit_network==true then "dashboard" else "*"
							tag =  "place:rename"
							notify_user = !emit_network
							notification_manager.createNotification place_id,place_id,{
								old_name:old_place.name
								new_name:updated_attr.name
								type:old_place.type
								owner_uid:old_place.owner_uid
								creation_date:old_place.creation_date
							},tag,scope,notify_user,true
						callback err,old_place,updated_attr
			],cb
		#callback is called with true or false wether the place exist or not
		checkPlace:(place_id,cb)->
			getMainDatabase (err,_db)->
				_db.models.global.place.find({where:{id:place_id}},{raw:true}).done (err,place)->
					cb err,place?
		getPlace:(place_id,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			getMainDatabase (err,db)->
				db.models.global.place.__places__.getByid(place_id,options).done (err,place)->
					return cb "Place not found" if err==null and place==null
					cb err,place
		getPlaceFromName:(place_name,filter,cb)->
			if _.isUndefined cb
				cb = filter
				filter = {}
			where = {where:_.extend(filter,{name:place_name})}
			getMainDatabase (err,db)->
				db.models.global.place.find(where,{raw:true},include: [{model:db.models.global.contact,as:'owner'}]).done (err,place)->
					return cb "Place not found" if err==null and place==null
					cb err,place
		createPlaceId:(type,place_uid,owner)->
			place_uid = uuid.v4() if place_uid==null
			owner = account_lib.getUid() if owner==null
			return {
				place_id:"#{place_uid}@#{owner}"
				place_uid:place_uid
			}
		generateFolderNameSync:(place)->
			return null if place==null
			return @generateFolderName(place.id)
		generateFolderName:(place_id)->
			return place_id.replace /:/g,"_"
		generateFolderNameFromPlaceId:(place_id,cb)->
			return cb null,local_cache[place_id] if local_cache[place_id]
			#this action could sound strange as the place_id is enough to generate the place folder
			#but we do it anyway to be able to have a more complex name further
			@getPlace place_id,(err,place)=>
				return cb err if err?
				return cb "Place not found" if place==null
				local_cache[place_id] = @generateFolderName(place.id)
				cb null,local_cache[place_id]

	# try to recover place where some documents are missing
	api.getAllPlace {owner_uid:{ne:null},network_synced:1},(err,places)->
		return console.error err?.message||err if err
		_.each places,(place)->
			data =
				owner:place.owner_uid
				place:place.id
			protocol_builder.place.getBasicsDocuments(data).send()

	###
	%%%%%%%%%%%%%%%%%% http api definition %%%%%%%%%%%%%%%%%%%%%%%%
	###
	prefix = server.url_prefix.core_api+'/places'

	express.get "#{prefix}/",(req,res)->
		filter = {}
		filter.type = req.query.type if req.query.type
		options = {raw:true}
		options.ansambers = true if req.query.ansambers=="1"
		api.getAllPlace filter,options,(err,places)->
			res.send {err:err,data:places}

	express.post "#{prefix}/", require_field_name, require_field_type, (req,res)->
		place_data = 
			creation_date:new Date
			type:req.body.type
			name:req.body_sanitized.name
			id: api.createPlaceId(req.body.type,null,null).place_id
			owner_uid:null
		api.addPlace place_data,{auto_validate:true},(err,place)->
			res.send {err:err,data:place}

	express.delete "#{prefix}/",(req,res)->
		api.deleteAllPlace (err,number)->
			res.send {err:err,data:number}

	express.get "#{prefix}/random_place/",(req,res)->
		api.createRandomPlace "conversation", null, (err,place)->
			res.send {err:err,data:place}		

	express.get "#{prefix}/:place_id", require_place_id, (req,res)->
		place_id = req.place_id
		filter = {}
		filter.type = req.query.type if req.query.type
		options = {raw:true}
		options.ansambers = true if req.query.ansambers=="1"
		api.getPlace req.place_id,filter,(err,places)->
			res.send {err:err,data:places}

	express.put "#{prefix}/:place_id", require_place_id, (req,res)->
		place_data = 
			creation_date:new Date
			owner_uid:null
			id:req.param "place_id"
		place_data.name = req.body_sanitized.name if req.body.name
		place_data.desc = req.body_sanitized.desc if req.body.desc
		api.updatePlaceHumanAttributes place_data.id, place_data, {},(err,place)->
			res.send {err:err,data:place}

	express.delete "#{prefix}/:place_id",require_place_id,(req,res)->
		api.deletePlaceById req.place_id,(err,deleted)->
			res.send {err:err,deleted:deleted}

	express.post "#{prefix}/:place_id/status/:status",require_place_id,(req,res)->
		place_id = req.place_id
		status = req.param 'status'
		_when.promise (resolve,reject)->
			return reject "Invalid status" if _.keys(api.status).indexOf(status)==-1
			api._changePlaceStatus place_id,{status:status},(err,place)->
				if err==null then resolve(place.values) else reject(err)
		.then (place)->
			res.send {err:null,data:place}
		,(error)->
			res.send {err:error,data:null}
		.catch (error)->
			res.send {err:error,data:null}

	express.post "#{prefix}/:place_id/accept",require_place_id,(req,res)->
		api._changePlaceStatus req.place_id,{status:"validated"},(err,place)->
			res.send {err:err,data:place}

	express.get "#{prefix}/unique/:uid/:type",(req,res)->
		uid = req.param('uid')
		type = req.param('type')
		options = {}
		options.ansambers = true if req.query.ansambers=="1"
		api.getUniquePlaceWithContact uid,{type:type},options,(err,place)->
			res.send {err:err,place:place}

	register null,{"api.place":api}
