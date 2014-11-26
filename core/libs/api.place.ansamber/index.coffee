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
utils = require "../../common_lib/utils"
async = require 'async'
_ = require 'underscore'
EventEmitter = require('eventemitter2').EventEmitter2
require_place_name = require("../../common_lib/express_middlewares").require_place_name
require_place_id = require("../../common_lib/express_middlewares").require_place_id
require_uid = require("../../common_lib/express_middlewares").require_uid

module.exports = (options,imports,register)->
	db = imports.database_manager
	account_lib = imports["api.account"]
	server = imports.server
	express = server.app
	events = imports["events"].namespaced("ansamber")
	protocol_builder = imports["protocol.builder"]
	notification_manager = imports["notification_manager"]

	getMainDatabase = (cb)->
		db.getApplicationDatabase cb

	api = new EventEmitter
	_.extend api,
		status:
			accepted:'validated'
			pending:'pending'
			requested:'requested'
			removed:'removed'
		getAnsambersOfPlace:(place_id,cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.ansamber.__places__.getAnsambersForPlace(place_id,{raw:true}).done cb
			],cb
		getAnsamberOfPlace:(place_id,uid,cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.ansamber.__places__.getAnsamberForPlace(place_id,uid,{raw:true}).done cb
			],cb
		#this function will just add the ansamber to the database
		# @options = {ansamber_object:#Sequelize ansamber object or null}
		# if options.ansamber_object is defined (null or object), then no extra query to fetch it is done
		_addAnsamber:(place_id,uid,ansamber_option,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					if _.isObject(options?.ansamber_object)
						callback null,options.ansamber_object
					else
						main_db.models.global.ansamber.__places__.getAnsamberForPlace(place_id,uid,{include_alias:false})
						.done (err,ansamber)->
							callback err,ansamber,main_db
				(ansamber,main_db,callback)->
					# the ansamber could be here but with a "removed" status
					if ansamber?
						return callback "The ansamber is already in the place"
					else
						ansamber_option = _.extend {
							admin:false
							status:api.status.pending
							request_id:null
							firstname:""
							lastname:""
						},ansamber_option
						ansamber_option.uid = uid
						ansamber_option.place_id = place_id
						aliases = ansamber_option.aliases || []
						delete ansamber_option.aliases
						main_db.models.global.ansamber.__places__.addAnsamber(ansamber_option,aliases).done callback
			],(err,new_ansamber)->
				ansamber_values = null
				if err==null
					ansamber_values = new_ansamber.values
					events.emit 'new',place_id,ansamber_values
				cb err,ansamber_values
		_updateAnsamber:(place_id,uid,update,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			#TODO validate the request_id thanks to ref_id
			aliases = update.aliases || null
			previous_ansamber_values = null
			delete update.aliases
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					if _.isObject(options?.ansamber_object)
						callback null,options.ansamber_object
					else
						main_db.models.global.ansamber.__places__.getAnsamberForPlace(place_id,uid,{include_alias:false}).done callback
				(ansamber,callback)->
					return callback "Ansamber #{uid} not found into place #{place_id}" if ansamber==null
					previous_ansamber_values = _.clone(ansamber.toJSON())
					_.each update,(item,key)->
						ansamber.set(key,item)
					ansamber.save().done callback
				(ansamber,callback)->
					return callback null,ansamber if aliases == null
					async.each aliases,(alias,_callback)->
						a = main_db.models.global.ansamber_alias.build(alias)
						ansamber.addAliases(a).done _callback
					,(err)->callback(err,ansamber)
			],(err,ansamber)->
				return console.log err if err?
				event_name = 'update'
				previous_status = previous_ansamber_values?.status
				#special case to create the ansamber on client side if this one was marked as "removed"
				if previous_status == api.status.removed and previous_status != ansamber.status
					event_name = 'new'
				events.emit event_name,place_id,ansamber.values
				cb err,ansamber.values
		_createOrUpdateAnsamber:(place_id,uid,ansamber_option,cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.ansamber.__places__.getAnsamberForPlace(place_id,uid,{include_alias:false}).done (err,ansamber)->
						callback err,main_db,ansamber
				(main_db,ansamber,callback)->
					options =
						ansamber_object:ansamber
					if ansamber == null #ansamber not found, let's create it
						api._addAnsamber place_id,uid,ansamber_option,options,callback
					else
						api._updateAnsamber place_id,uid,ansamber_option,options,callback
			],cb
		#this method will add the ansamber and trigger a 'new ansamber' event + an add_ansamber request
		addAnsamberToPlace:(place_id,uid,ansamber_option,cb)->
			if _.isUndefined(cb)
				cb = ansamber_option
				ansamber_option = null
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(db,callback)->
					db.models.global.contact.__places__.getContactByUid(uid,{raw:false}).done (err,contact)->
						return callback err if err? 
						return callback 'Contact not found' if contact == null
						callback null,contact,db
				(contact,db,callback)->
					db.models.global.place.find({where:{id:place_id}},{raw:false}).done (err,place)->
						return callback(err) if err?
						return callback("Place not found") if place==null
						callback null,contact,place
				(contact,place,callback)->
					return callback "You're not allowed to add ansamber" if place.owner_uid!=null
					parsed_id = utils.parsePlaceId(place.id)
					network_object = protocol_builder.place.addAnsamberRequest({
						place_id:parsed_id.uuid
						user_uid:uid
						name:place.name||""
						type:place.type
						desc:place.desc
						creation_date:+new Date(place.creation_date)
						place_uid:place.id
						owner_uid:place.owner_uid||account_lib.getUid()
					})
					ansamber_option = _.extend ansamber_option, 
						request_id:network_object.getMessageId()
						firstname:contact.firstname
						lastname:contact.lastname
						status:api.status.pending
					ansamber_option.status ?= api.status.requested
					api._createOrUpdateAnsamber place.id,uid,ansamber_option,(err,ansamber)->
						callback err,ansamber,network_object
				(ansamber,network_object,callback)->
					network_object.send (err,reply)->
						#TODO manage the case where reply.code!=202
						if reply.code!=202
							console.error "Receive a non-202 return code"
					callback(null,true)
			],(err)->
				cb err,err==null
		addAliasesToAnsamber:(id,aliases,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			added_alias= []
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.ansamber_alias.__places__.addAliases(id,aliases,options).done callback
				(results,callback)->
					_.each results,(alias)-> added_alias.push(alias) if alias.id?
					callback null
			],(err)->
				cb(err,added_alias)
		changeAnsamberStatus:(place_id,uid,status,cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(db,callback)->
					db.models.global.place.find({where:{id:place_id}}).done callback
				(place,callback)->
					return callback "Place not found" if place==null
					callback null,place
			],(err,place)->
				return cb err,null if err
				api._updateAnsamber place_id,uid,{status:status},(err,ansamber)->
					if err==null and ansamber? and status=api.status.accepted
						if place.type=="share"
							notification_manager.createNotification place_id,uid,{
								place_id:place_id
								uid:uid
								firstname:ansamber.firstname
								lastname:ansamber.lastname
								place_name:place.name
							},"ansamber:accepted","*",true,true
					cb err,ansamber
		removeAnsamberFromPlace:(place_id,uid,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			options = _.extend {emit_network:true,notify_ui:false},options
			message = null
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					if options?.ansamber_object?
						callback null,options.ansamber_object
					else
						main_db.models.global.ansamber.find({where:{place_id:place_id,uid:uid}}).done callback
				(ansamber,callback)->
					return callback "Ansamber not found" if ansamber == null
					return callback "Ansamber already removed" if ansamber.status == "removed"
					if options?.code == 403
						message = "You're not allowed to remove #{ansamber.getFullName()} to this place"
					return callback null,ansamber if options.emit_network != true
					protocol_builder.place.removeAnsamberRequest({place:place_id,user_uid:uid}).send (err,reply)->
						if reply.code==200
							callback null,ansamber
						else if reply.code == 403
							callback "You're not allowed !"
						else
							callback "Kernel didn't deleted the ansamber of place #{place_id}"
				(ansamber,callback)->
					ansamber.setAsRemoved().done (err)->callback(err)
			],(err)->
				events.emit 'remove',place_id,uid,message if err==null and options.notify_ui == true
				console.error err if err?
				_.isFunction(cb) and cb(err)
		removeAnsamberFromAllPlace:(uid,cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.ansamber.__places__.getPlacesForAnsamber(uid).done callback
				(places,callback)->
					if not _.isArray(places) or places.length == 0
						return callback "No place to remove the ansamber from"
					async.each places,(ansamber_with_place,_callback)->
						return callback null if ansamber_with_place.status == "removed"
						place_id = ansamber_with_place.place.id
						options = 
							ansamber_object:ansamber_with_place
							notify_ui:true
						api.removeAnsamberFromPlace place_id,uid,options,_callback
					,callback
			],cb
	###
	%%%%%%%%%%%%%%%%%% http api definition %%%%%%%%%%%%%%%%%%%%%%%%
	###

	## Ansamber [/core/api/v1/places/{?place_id}/ansambers/{ansamber}]

	prefix = server.url_prefix.core_api+'/places'

	express.get "#{prefix}/:place_id/ansambers/",require_place_id,(req,res)->
		api.getAnsambersOfPlace req.place_id,(err,ansambers)->
			res.send {err:err,ansambers:ansambers}
	
	express.get "#{prefix}/:place_id/ansambers/:uid",require_place_id, require_uid,(req,res)->
		api.getAnsamberOfPlace req.place_id, req.uid,(err,ansamber)->
			res.send {err:err,ansamber:ansamber}

	express.put "#{prefix}/:place_id/ansambers/:uid",require_place_id, require_uid,(req,res)->
		place_id = req.place_id
		ansamber_option = req.body
		api.addAnsamberToPlace place_id,req.uid,ansamber_option,(err,added)->
			return res.send {err:err,ok:added}

	express.delete "#{prefix}/:place_id/ansambers/:uid",require_place_id, require_uid,(req,res)->
		place_id = req.place_id
		api.removeAnsamberFromPlace place_id,req.uid,(err)->
			return res.send {err:err,ok:err==null}



	register null,{'api.place.ansamber':api}

