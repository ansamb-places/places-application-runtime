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
networkMsgHelper = require '../../common_lib/NetworkMessageHelper'
require_query = require("../../common_lib/express_middlewares").require_query
require_field = require("../../common_lib/express_middlewares").require_field
require_field_uid = require("../../common_lib/express_middlewares").require_field_uid
require_uid = require("../../common_lib/express_middlewares").require_uid
MemCache = require 'mem-cache'

contactSearchCache = new MemCache
cacheTimeout = 5000

module.exports = (options,imports,register)->
	db = imports.database_manager
	avatar_manager = imports["avatar_manager"]
	protocol_builder = imports["protocol.builder"]
	account_lib = imports["api.account"]
	place_lib = imports["api.place"]
	ansamber_lib = imports["api.place.ansamber"]
	external_service_manager = imports["external_service_manager"]
	events = imports.events.namespaced("contact")
	server = imports.server
	notification_manager = imports["notification_manager"]
	express = server.app
	NG_ALIAS = options.ng_alias || null

	getMainDatabase = (cb)->
		db.getApplicationDatabase cb
	#API definition
	api = 
		status:
			accepted:'validated'
			pending:'pending'
			later:'later'
			requested:'requested'
			removed:'removed'
		getAllContact:(options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {raw:true}
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					where = {}
					where = options.where if typeof options.where != 'undefined'
					main_db.models.global.contact.__places__.getApplicationContacts({where: where, options:options}).done callback
			],(err,contacts)->
				if _.isArray(contacts)
					contacts = _.map contacts,(item)->api.createContactDocument(item)
				cb err,contacts
		createContactDocument:(contact_obj,options)->
			data = _.clone(contact_obj)
			if contact_obj.message == "disable_conv"
				data.conversation_id = null
				data.conversation_ready = false
			else
				data.conversation_id = place_lib._generateUniquePlaceId(contact_obj.uid).place_id
				data.conversation_ready = options?.conversation_ready ? true
			if _.isArray(data.aliases)
				data.aliases = data.aliases[0] ? null
			return data
		addContact:(contact_data,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					options.raw = true
					options.aliases ?= []
					main_db.models.global.contact.__places__.addContact(contact_data,options.aliases,options).done callback
			],(err,contact_obj)->
				if err==null
					if contact_obj.status == api.status.pending
						notif_data =
							uid:contact_obj.uid
							firstname:contact_obj.firstname
							lastname:contact_obj.lastname
							status:contact_obj.status
						notification_manager.createNotification(null,contact_obj.uid,notif_data,'contact','*',true,true)
					events.emit 'create',api.createContactDocument(contact_obj)
				cb(err,contact_obj)
		addContactRequest:(alias_options,cb)->
			async.waterfall [
				(callback)->
					api.searchContactOnServer alias_options,callback
				(contact,callback)->
					return callback "Contact not found" if contact == null
					contact.message = "Do you want to be my friend?" unless "string" == typeof contact.message
					protocol_builder.contact.addContactRequest({
						uid:contact.uid
						message:contact.message
					}).send (err,reply)->
						return callback("error:#{reply.code}",null) if reply.code!=202
						contact.status = api.status.requested
						contact.request_id = reply.ref_id
						aliases = networkMsgHelper.aliasesDbArrayAdapter(contact.aliases,{first_as_default:true})
						api.addOrUpdateContact contact,{aliases:aliases},callback
			],cb
		addAliasesToContact:(uid,aliases,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			added_alias= []
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.contact_alias.__places__.addAliases(uid,aliases,options).done callback
				(results,callback)->
					_.each results,(alias)-> added_alias.push(alias) if alias.id?
					callback null
			],(err)->
				cb(err,added_alias)
		#TODO
		deleteAllContact:(cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.contact.destroy().done callback
			],cb
		removeContactByUid:(uid,options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {}
			options = _.extend {emit_network:true,notify_ui:false},options
			contact = null
			async.waterfall [
				(callback)->
					api.getContactByUid uid,{raw:false},(err,_contact)->
						if err == null
							if _contact?
								contact = _contact
								callback null
							else
								callback "Contact not found"
						else
							callback err
				(callback)->
					if options.emit_network == true
						protocol_builder.contact.removeContact({uid:uid}).send (err,reply)->
							if reply.code == 200
								callback null
							else
								callback reply?.desc||"Unknwon error (code #{reply.code})"
					else
						callback null
				(callback)->
					# if the content comes from the network, we don't perform any implicit operations
					# because it's the responsability of the origin to do so
					if options.emit_network == false
						return callback null
					#leave all places own by the contact
					contact.getMyPlaces().done (err,places)->
						return callback err if err?
						async.each _.where(places,{type:"share"}),(place,_callback)->
							#disable all share place
							place_lib.disablePlace place.id,{emit_network:true,notify_ui:true},_callback
						,(err)->
							console.log err if err?
							callback null
				(callback)->
					#disable the conversation place
					place_lib.getUniquePlaceWithContact uid,{type:"conversation"},{raw:false},(err,place)->
						return callback err if err?
						_options= 
							emit_network:false # we don't have to emit network message because it's done just after
							notify_ui:true
						place_lib.disablePlace place.id,_options,callback
				(callback)->
					# if the content comes from the network, we don't perform any implicit operations
					# because it's the responsability of the origin to do so
					if options.emit_network == false
						return callback null
					ansamber_lib.removeAnsamberFromAllPlace uid,(err)->
						callback null
				(callback)->
					contact.setAsRemoved().done (err)->callback(err)
				(callback)->
					notification_manager.createNotification null,contact.uid,{
						uid:contact.uid
						firstname:contact.firstname
						lastname:contact.lastname
						status:'deleted'
					},'contact','*',false,true
					events.emit 'delete',uid if options.notify_ui
					callback null
			],cb
		getContactByUid:(uid,options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {raw:true}
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.contact.__places__.getContactByUid(uid,options).done callback
			],cb
		#update = {ansamber:ansamber updates, contact: contact updates}
		updateContact:(uid,update,options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {}
			async.waterfall [
				(callback)=>
					return callback("Update can't be null",null) if update==null
					return callback("update must be an object",null) if not _.isObject(update)
					return callback null,options.contact_obj if options?.contact_obj
					@getContactByUid uid,{raw:false,include_removed:true},(err,contact)->
						callback err,contact
				(contact,callback)->
					return callback("Uid not found",null) if contact==null
					old_status = contact.status
					status = update.status || contact.status
					allowed_updates = ['status','firstname','lastname','request_id']
					client_patch = {}
					for attr_update in allowed_updates
						if update.hasOwnProperty(attr_update)
							contact[attr_update] = update[attr_update]
							client_patch[attr_update] = update[attr_update]
					contact.save().done (err)->
						callback err,old_status,status,contact,client_patch
				(old_status,status,contact,client_patch,callback)=>
					if update.aliases
						@addAliasesToContact uid,update.aliases,(err,results)->
							callback null,old_status,status,contact,client_patch
					else
						callback null,old_status,status,contact,client_patch
			],(err,old_status,status,contact,client_patch,callback)->
				return cb err,null if err?
				if (old_status==api.status.pending or old_status==api.status.later) and status==api.status.accepted
					protocol_builder.contact.addContactReply({
						uid:uid
						ref_id:contact.request_id
						accepted:true
						message:"Welcome friend"
					}).send()
				if old_status!=status
					emit_event = (options)->
						options?={}
						if old_status == api.status.removed
							events.emit 'create',api.createContactDocument(contact.toJSON(),options)
						else
							events.emit 'update',uid,_.extend(client_patch,{conversation_ready:options.conversation_ready ? false})
					if status==api.status.accepted
						#the notification has a global scope if someone else accept our request
						#but we just want the notification displayed into dashboard in other cases
						scope = '*'
						notify_user = true
						#request comes from someone else
						if old_status==api.status.requested 
							scope = '*'
							notify_user = true
						else
							scope = 'dashboard'
							notify_user = false
						notification_manager.createNotification null,contact.uid,{
							uid:contact.uid
							firstname:contact.firstname
							lastname:contact.lastname
							status:status
						},'contact',scope,notify_user,true
						opts = 
							conv_create:options?.conv_create ? true
						if contact.message == "disable_conv"
							emit_event {conversation_ready:false}
						else
							place_lib.createUniquePlaceWithContact uid,{type:'conversation'},opts,(err,p)->
								return console.log err if err?
								emit_event {conversation_ready:p?}
					else
						emit_event()
				cb(err,contact.values)
		# this method will be called by the kernel when an add_request is received from the network
		# we can't just make a classic add because the request can concern a removed contact which is still into the db
		addOrUpdateContact:(contact_data,options,cb)->

			async.waterfall [
				(callback)->
					api.getContactByUid contact_data.uid,{raw:false,include_removed:true},callback
				(contact,callback)->
					if contact == null
						api.addContact contact_data,options,callback
					else
						update = contact_data
						update.status ?= api.status.pending
						api.updateContact contact.uid,update,{contact_obj:contact},callback
			],cb
		searchContactOnServer:(alias,cb)->
			return cb "Invalid alias object" if not _.isObject(alias)
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					found_alias = _.findWhere account_lib.getAllAliases(),alias
					if found_alias
						return callback "Trying to add yourself"
					else
						main_db.models.global.contact_alias.__places__.getContactForAlias(alias,{raw:true}).done callback
				(contact,callback)->
					key = networkMsgHelper.aliasObjectToAnsambFormat(alias)
					if contact == null
						return callback null,cc if (cc=contactSearchCache.get(key))?
						args = {a:key}
						external_service_manager.requestService "alias_search",args,(err,reply)->
							return callback err if err?
							contactSearchCache.set key,reply.data,cacheTimeout if reply?.data?
							callback null,reply?.data||null
					else
						return callback "Friend already added",contact
			], cb
			
			
		setContactsStatus:(contacts)->
			events.emit 'status',contacts

		syncContactStatus:->
			# we don't need to handle the reply as its the business of the proto handler
			protocol_builder.contact.syncStatus().send()

	#http api definition
	#
	_require_type = (req,res,next) ->
		require_field("type", req, res, next)

	_require_alias = (req,res,next) ->
		require_field("alias", req, res, next)

	prefix = server.url_prefix.core_api+'/contacts'
	

	express.get "#{prefix}/",(req,res)->
		where = {}
		where.status = req.param("status") if typeof req.param("status") != "undefined"
		api.getAllContact {raw:true, where:where, include_removed : true},(err,contacts)->
			res.send {err:err,data:contacts}

	express.post "#{prefix}/", _require_alias, _require_type, (req,res)->
		options =
			alias:req.alias
			type:req.type
		api.addContactRequest options,(err,contact)->
			res.send {err:err,data:contact}

	express.post "#{prefix}/accept", require_field_uid, (req,res) ->
		uid = req.uid
		api.updateContact uid,{status:api.status.accepted},{conv_create:true},(err,contact)->
			res.send {err:err,ok:contact?}

	express.post "#{prefix}/reject", require_field_uid, (req,res) ->
		uid = req.uid
		api.removeContactByUid uid,(err)->
			res.send {err:err}

	express.post "#{prefix}/later", require_field_uid, (req,res) ->
		uid = req.uid
		api.updateContact uid,{status:api.status.later},(err,contact)->
			res.send {err:err,ok:contact?}

	express.get "#{prefix}/get_ng_contact/",(req,res)->
		api.searchContactOnServer {type:"email",alias:NG_ALIAS},(err,contact)->
			contact= contact.contact if _.isObject(contact) and err != null
			err = if _.isObject(contact) then null else err
			res.send {err:err,contact:contact||null}

	express.get "#{prefix}/add_ng/",(req,res)->
		if NG_ALIAS == null
			return res.send {err:"No alias defined for New Generation contact"}
		alias={type: "email", alias:NG_ALIAS}
		async.waterfall [
			(callback)->
				api.searchContactOnServer alias, callback
			(contact,callback)->
				if _.isObject(contact)
					protocol_builder.contact.addNG({uid:contact.uid}).send (err,reply)->
						err = "Network error" if err == null and reply?.code != 202
						callback err
				else
					callback "Contact not found"
		],(err)->res.send {err:err}

	express.get "#{prefix}/sync_status/",(req,res)->
		api.syncContactStatus()
		res.send 200

	express.delete "#{prefix}/:uid", require_uid, (req, res)->
		api.removeContactByUid req.uid,(err) ->
			res.send {err:err}

	express.get "#{prefix}/:uid", require_uid, (req,res) ->
		api.getAllContact {raw:true, where:{uid: req.uid}, include_removed:true}, (err,contacts)->
			contact = if _.isArray(contacts) then contacts[0] else contacts
			res.send {err:err,data:contact}

	express.post "#{prefix}/aliases/lookup",
		_require_alias, 
		_require_type, 
		(req,res)->
			api_options =
				alias:req.alias
				type:req.type
			api.searchContactOnServer api_options,(err,contact)->
				res.send {err:err,contact:contact||null}

	#register service
	register null,{"api.contact":api}
