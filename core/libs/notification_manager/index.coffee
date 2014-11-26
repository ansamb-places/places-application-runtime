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
require_place_name = require("../../common_lib/express_middlewares").require_place_name

module.exports = (options,imports,register)->
	db_manager = imports['database_manager']
	server = imports['server']
	events = imports['events'].namespaced("notification")

	api =
		createNotification:(place_id,ref,data,tag,scope,notify_user,store,cb)->
			notification =
				place_id:place_id
				ref:ref
				date:new Date()
				data:data
				tag:tag #use for event demux
				scope:scope #"*" for a global broadcast or the name of a specific service (ex:'dashboard')
				read:!notify_user
			if store==true
				async.waterfall [
					(callback)->
						db_manager.getApplicationDatabase callback
					(main_db,callback)->
						main_db.models.global.notification.create(api.marshalNotif(notification)).done callback
					(db_notif,callback)->
						events.emit "new",api.unmarshalNotif(db_notif.values) if notify_user
						callback null
				],(err)->
					console.log err if err?
					cb err if _.isFunction cb
			else
				events.emit "new",notification if notify_user
				cb null,null if _.isFunction cb
		updateNotification:(place_id,ref,data,tag,notify_user,cb)->
			where =
				place_id:place_id
				ref:ref
				tag:tag
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(main_db,callback)->
					main_db.models.global.notification.find({where:where}).done callback
				(notification,callback)->
					return callback "Notification not found" if notification==null
					_data = null
					try
						_data = _extend(JSON.parse(notification.data),data)
					catch e
						return callback "Invalid json"
					notification.data = JSON.stringify _data
					notification.read = !notify_user
					notification.date = new Date()
					notification.save().done (err)->
						callback err,notification.values
				(notification,callback)->
					events.emit "update",notification.id,notification if notify_user
					callback null
			],(err)->
				console.log err if err?
				cb err if _.isFunction cb
		getNotifications:(filter,cb)->
			if _.isUndefined(cb)
				cb = filter
				filter = {}
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(main_db,callback)->
					#also include notifications which belongs to the global scope
					filter.scope = ['*',filter.scope] if not _.isUndefined(filter.scope)
					main_db.models.global.notification.findAll({where:filter,order:'read DESC,date ASC'},{raw:true}).done callback
				(notifs,callback)->
					callback null,_.map(notifs,(item)->api.unmarshalNotif(item))
			],cb
		unmarshalNotif:(db_notif)->
			res = _.clone db_notif
			res.data = JSON.parse res.data			
			res.read = !!res.read
			return res
		marshalNotif:(notif)->
			res = _.clone notif
			res.data = JSON.stringify(res.data)
			return res
		deleteNotification:(id,cb)->
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(main_db,callback)->
					filter = {}
					if id?
						filter = {id:id}
					main_db.models.global.notification.destroy(filter).done callback
			],cb
		markAsRead:(id,cb)->
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(main_db,callback)->
					filter = {}
					if id?
						filter = {id:id}
					main_db.models.global.notification.update({read:1},filter).done callback
			],cb
	###
		HTTP API
	###

	prefix = server.url_prefix.core_api+"/notifications"
	express = server.app

	express.get "#{prefix}/",(req,res)->
		scope = req.query.scope
		filter = {}
		filter.scope = scope if not _.isUndefined scope
		filter.place_id = req.query.place_name if not _.isUndefined(req.query.place_name)
		api.getNotifications filter,(err,notifications)->
			res.send {err:err,data:notifications}

	express.delete "#{prefix}/:id?",(req,res)->
		api.deleteNotification req.param('id')||null,(err)->
			res.send {err:err,ok:err==null}

	express.get "#{prefix}/mark_read",(req,res)->
		id = req.query.id || null
		api.markAsRead id,(err)->
			res.send {err:err,ok:err==null}

	register null,{notification_manager:api}