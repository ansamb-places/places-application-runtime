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
{EventEmitter} = require 'events'
_ = require 'underscore'
uuid = require 'node-uuid'
async = require 'async'
path = require 'path'
ContentSyncManager = require './ContentSyncManager'
ContentFacade = require '../../common_lib/ContentFacade'

module.exports = (options,imports,register)->
	db_manager = imports.database_manager
	com_layer = imports.communication_layer
	_ = require 'underscore'
	place_lib = imports["api.place"]
	ansamber_lib = imports["api.place.ansamber"]
	events = imports.events.namespaced("content")
	protocol_builder = imports["protocol.builder"]
	#private functions
	handlePutReply = (reply,content_object,cb)->
		if reply.code!=202
			console.error "Error while sending content PUT",reply
			cb and cb "Error on content PUT (code #{reply.code})"
		else
			#check if we have to store some extra data generated by the kernel
			if reply?.data?.ansamb_extras
				extra = reply?.data?.ansamb_extras
				try
					extra = JSON.stringify(extra)
				catch e
					return cb e if _.isFunction cb
				content_object.updateAttributes
					ansamb_extras:extra
				.done (err)->
					cb and cb err
	marshallDbObject = (content_attr)->
		tmp = _.clone content_attr
		if tmp?.ansamb_extras?
			try
				tmp.ansamb_extras = JSON.stringify content_attr.ansamb_extras
			catch e
				console.log "Error on JSON stringify while marchelling object"
				tmp.ansamb_extras = null
		return tmp
	unmarshallDbObject = (content_attr)->
		tmp = _.clone content_attr
		if tmp?.ansamb_extras?
			try
				tmp.ansamb_extras = JSON.parse content_attr.ansamb_extras
			catch e
				console.log "Error on JSON stringify while unmarchelling object"
				tmp.ansamb_extras = null
		return tmp

	downloadable_content_types = ['file']
	content_downloaded_state = 
		"file:stream":true
	#node api
	api = new EventEmitter
	_.extend api,
		addContent:(place_id,content_options,cb)->
			emit_network = content_options.emit_network ? true
			notify_ui = content_options.notify_ui ? true
			args = content_options.args
			content = 
				id:content_options.id||uuid.v4()
				rev:content_options.rev||uuid.v4()
				owner:content_options.owner||null
				content_type:content_options.content_type
				date:content_options.date||new Date
				ref_content:content_options.ref_content||null
				read:content_options.read ? false
				downloadable:downloadable_content_types.indexOf(content_options.content_type)!=-1
				downloaded:content_downloaded_state[content_options.content_type] ? content_options.downloaded ? true
				uploaded: content_options.uploaded ? false
				ansamb_extras:content_options.ansamb_extras||null
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(db,callback)->
					db.models.global.place.find({where:{id:place_id}},{raw:false}).done callback
				(place,callback)->
					return callback "Place not found" if place==null
					db_manager.getDatabaseForPlace place_id,(err,db)->
						callback err,place,db
				(place,db,callback)->
					db.models.global.content.create(marshallDbObject(content)).done (err,c)->
						callback err,place,c
			],(err,place,c)->
				return cb err,null if err?
				if place.isDisabled()
					emit_network = false
					notify_ui = false
				cb err,c.values,(err,data,owner)->
					return console.error(err) if err?
					dst_uid = '*'
					if emit_network==true
						put_object =
							place:place_id
							dst:dst_uid
							content_id:c.id
							content_type:c.content_type
							date:c.date
							rev:c.rev
							ref_content:c.ref_content||null
							data:data
							#ansamb_extras:content.ansamb_extras||null
						put_object.args = args if args?
						protocol_builder.content.putRequest(put_object).send (err,reply)->
							handlePutReply reply,c
					if notify_ui==true
						console.log "Emit websocket event"
						if err==null
							options =
								content:c.values
								data:data
								owner:owner
							events.emit "new",place.values,ContentFacade.createClientDocument(options),(read)->
								if read==true and c.read==false
									c.updateAttributes({read:true})
		countContent:(place_id,filter,cb)->
			async.waterfall [
				(callback)->
					db_manager.getDatabaseForPlace place_id,callback
				(db,callback)->
					db.models.global.content.count({where:filter}).done callback
			],cb
		updateContentOnly:(place_id,content_options,cb)->
			content_id = content_options.id
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(db,callback)->
					db.models.global.place.find({where:{id:place_id}},{raw:false}).done (err,place)->
						if place==null
							callback "Place not found"
						else
							callback null,place
				(place,callback)->
					api.getContentById place_id,content_id,{raw:false,unmarshall:false},(err,content)->
						callback err,place,content
				(place,c,callback)->
					whiteList = ["owner","downloaded","uploaded"]
					_.each whiteList,(attr)->
						c[attr] = content_options[attr] if _.has(content_options,attr)
					c.save(whiteList).done (err)->
						callback err,place,c
			],(err,place,c)->
				return cb err,null if err?
				cb err,c.values
		renameFileContent:(place_id,options,cb)->
			options.emit_network= options.emit_network || false
			network_promise = options.network_promise
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(db,callback)->
					db.models.global.place.find({where:{id:place_id}},{raw:false}).done (err,place)->
						if place==null
							callback "Place not found"
						else
							callback null,place
				(place,callback)->
					db_manager.getDatabaseForPlace place_id,(err,db)->
						callback err,db,place
				(db,place,callback)->
					new_content_id = options?.app_options.new_content_id
					return callack "Wrong new_content_id" if typeof new_content_id != "string"
					new_rev = options.new_rev ? uuid.v4()
					update = {id:new_content_id,rev:new_rev}
					db.models.global.content.update(update,{id:options.old_content_id}).done (err)->
						callback err,place,new_rev
			],(err,place,new_rev)->
				return cb err,null if err?

				valid_operation = (final_cb)->
					network_promise.resolve final_cb
				reject_operation = (final_cb)->
					network_promise.reject()
					final_cb()

				if options.emit_network == true
					if !place.isDisabled()
						data =
							place:place_id
							old_content_id:options.old_content_id
							content_type:options.content_type
							data:_.extend(options?.app_options,{rev:new_rev})
						protocol_builder.content.renameRequest(data).send (err,reply)->
							return cb err if err?
							if reply.code==200
								valid_operation (err)->
									cb err
							else
								reject_operation ->
									cb reply.desc
					else
						valid_operation (err)->
							cb err

				else
					valid_operation (err)->
						if err == null
							rename_options = 
								new_content_id:options?.app_options.new_content_id
								relative_path:options?.app_options.relative_path
								name:options?.app_options.name
							events.emit "rename",place_id,options.old_content_id,rename_options
						cb err
		updateContent:(place_id,content_options,cb)->
			content_id = content_options.id
			content_options.rev = content_options.rev||uuid.v4()
			content_options.date = content_options.date||new Date
			async.waterfall [
				(callback)->
					db_manager.getApplicationDatabase callback
				(db,callback)->
					db.models.global.place.find({where:{id:place_id}},{raw:false}).done (err,place)->
						if place==null
							callback "Place not found" 
						else
							callback null,place
				(place,callback)->
					api.getContentById place_id,content_id,{raw:false,unmarshall:false},(err,content)->
						callback err,place,content
				(place,c,callback)->
					return callback "content not found" if c == null
					_.extend c,{read:false} if !content_options.emit_network
					whiteList = ["rev","date","ansamb_extras","downloaded","uploaded","read"]
					_.each whiteList,(attr)->
						c[attr] = content_options[attr] if _.has(content_options,attr)
					#TODO clean this (only for test)
					c.ansamb_extras = JSON.stringify(c.ansamb_extras) if c.ansamb_extras?
					c.save(whiteList).done (err)->
						callback err,place,c
			],(err,place,c)->
				return cb err,null if err?
				notify_ui = !content_options.emit_network
				if place.isDisabled()
					content_options.emit_network = false
					notify_ui = false
				cb err,c.values,(err,data)->
					return console.error(err) if err?
					dst_uid = '*'
					if _.isUndefined(content_options.emit_network) or content_options.emit_network==true
						put_object=
							place:place_id
							dst:dst_uid
							content_id:c.id
							content_type:c.content_type
							date:c.date
							rev:c.rev
							data:data
						put_object.args = content_options.args if content_options.args?
						protocol_builder.content.putRequest(put_object).send (err,reply)->
							handlePutReply reply,c
					else if notify_ui == true
						options =
							content:c.values
							data:data
						if err==null
							events.emit "update",place.values,ContentFacade.createClientDocument(options),(read)->
									if read==true and c.read==false
										c.updateAttributes({read:true}) 
		deleteContent:(place_id,content_options,cb)->
			content_options.emit_network = content_options.emit_network ? true
			getAndDeleteContent = (callback)->
				async.waterfall [
					(_callback)->
						return _callback "No id defined" if not content_options.id?
						api.getContentById place_id,content_options.id,{raw:true},(err,content)->
							return _callback "Content not found" if content==null and err==null
							_callback err,content
					(content,_callback)->
						db_manager.getDatabaseForPlace place_id,(err,db)->
							_callback err,content,db
					(content,db,_callback)->
						db.models.global.content.destroy({id:content_options.id},{limit:1}).done (err)->
							_callback err,content
				],callback
			async.parallel
				place:(callback)->place_lib.getPlace place_id,{raw:false},callback
				content:getAndDeleteContent
			,(err,result)->
				place = result.place
				content = result.content
				return cb err,null if err?
				notify_ui = !content_options.emit_network
				if place.isDisabled()
					content_options.emit_network = false
					notify_ui = false
				cb null,(content_app_deleted)->
					if content_app_deleted == true 
						if content_options.emit_network == true
							protocol_builder.content.deleteRequest({
								place:place_id
								content_id:content_options.id
								rev:content.rev
							}).send (err,reply)->
								#TOTO manage reply
						else if notify_ui == true
							place_return = place.values
							place_return.owner = place.owner?.values if place.owner
							events.emit "delete",place_return,content_options.id

		markContentAs:(place_id,content_id,status,cb)->
			state= null
			async.waterfall [
				(callback)->
					switch status
						when "read"
							state= true
						when "unread"
							state= false
						else
							callback "wrong status"
					callback null
				(callback)->
					db_manager.getDatabaseForPlace place_id,callback
				(db,callback)->
					filter = {}
					if content_id?
						filter.id = content_id #could be a string or an array
					db.models.global.content.update({read:state},filter).done callback
			],(err)->
				return cb err if err?
				patch = {}
				if _.isArray content_id
					_.each content_id,(item)->patch[item]={read:state}
				else if content_id?
					patch[content_id] = {read:state}
				else
					patch['*'] = {read:state}
				events.emit "read:update",place_id,patch
				cb null
		getContentForPlace:(place_id,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {raw:true}
			db_manager.getDatabaseForPlace place_id,(err,db)->
				return cb(err,null) if err?
				db.models.global.content.findAll({order: 'date ASC'},options).done cb
		getNewTransactionForPlace:(place_id,cb)->
				db_manager.getDatabaseForPlace place_id,(err,db)->
					if err
						cb err,null
					else 
						db.sequelize.transaction {autocommit:true,isolationLevel:'SERIALIZABLE'},(t)->
							cb(null,t)
		_getContentsWithFilter:(place_id,filter,options,cb)->
			db_manager.getDatabaseForPlace place_id,(err,db)->
				return cb(err,null) if err?
				db.models.global.content.findAll({where:filter,order:'date ASC'},options).done cb
		_getcontentWithFilterAndOrder:(place_id,filter,order_filter,options,cb)->
			db_manager.getDatabaseForPlace place_id,(err,db)->
				return cb(err,null) if err?
				db.models.global.content.find({where:filter,order:order_filter},options).done cb
		getContentById:(place_id,id,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			options = _.extend {
				raw:false
				unmarshall:true
			},options
			async.waterfall [
				(callback)->
					db_manager.getDatabaseForPlace place_id,callback
				(main_db,callback)->
					main_db.models.global.content.find({where:{id:id}},{raw:options.raw}).done callback
			],(err,content)->
				return cb err,null if err?
				return cb "Content not found",null if content == null
				if options.unmarshall==true
					content_attr = if options.raw==true then content else content.values
					cb null,unmarshallDbObject(content_attr)
				else
					cb null,content
		checkContent:(place_id,id,cb)->
			db_manager.getDatabaseForPlace place_id,(err,db)->
				return cb(err,null) if err?
				db.models.global.content.find({where:{id:id}},{raw:true}).done (err,content)->
					cb err,content?


	register null,{"content_manager":api}
