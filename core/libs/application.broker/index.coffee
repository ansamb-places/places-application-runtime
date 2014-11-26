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
SpecialContentManager = require './SpecialContentManager'
path = require 'path'
async = require 'async'
cache = {}
_when = require 'when'
_ = require 'underscore'
mkdirp = require 'mkdirp'
fs = require 'fs'
ContentFacade = require '../../common_lib/ContentFacade'
utils = require '../../common_lib/utils'

module.exports = (options,imports,register)->
	server = imports.server
	express = server.app
	db_manager = imports.database_manager
	place_lib = imports["api.place"]
	websocket = imports.client_websocket
	com_layer = imports.communication_layer
	content_lib = imports["content_manager"]
	application_registery = imports["application.registery"]

	#############################################################################################
	############################# APPLICATION CONTEXT MANAGEMENT ################################
	#############################################################################################
	buildCacheKey = (app_name,place_id)->
		return app_name+"@"+place_id
	contextForApp = (app_name,place_id,cb)->
		cb(new Error("Place name is missing"),null) if _.isUndefined(place_id)
		key = buildCacheKey app_name,place_id
		app = application_registery.getAppByName(app_name)
		if app==null
			return cb(new Error("Application #{app_name} not found"),null)
		unless cache.hasOwnProperty(key)
			context_ready = _when.defer()
			console.log "create context #{buildCacheKey(app_name,place_id)}"
			async.parallel
				_database:(callback)->
					models_path=[]
					if app? and app.hasOwnProperty('models_dir')
						models_path.push {path:path.join(app.path,app.models_dir),prefix:app_name}
					#TODO modify database_manager to allow to bypass models sync
					db_manager.getDatabaseForPlace(
						place_id,
						models_path,
						callback
					)
				socket:(callback)->
					callback null,websocket.namespace_socket(app_name)
			,(err,context)->
				context_ready.promise.then (context)->
					cache[key] = context unless err?
					cb null,context
				,(error)->
					cb error,null
				.catch (error)->
					cb err,null
				return context_ready.reject err if err?
				#sandbox database models to let the application access only his own models
				if context._database.models.prefixed[app_name]
					context.database = 
						models:context._database.models.prefixed[app_name]
				delete context._database

				#add communication api into context
				context.place_id = place_id
				context.app_name = app_name
				context.app_path = app.path
				#create a specific content_lib for this context
				context.content_lib = 
					addCollection:(callback)->
						contentCreate = _when.defer()
						contentCreate.promise.then (reply)->
							callback null,reply
						,(error)->
							callback error,null
						content_options =
							content_type:'collection'
							notify_ui:false
						data=
							app_children_type: app.contentType
						content_lib.addContent place_id,content_options,(err,content,done)->
							return contentCreate.reject(err) if err?
							api.crud.create place_id,content,data,null,(err,final_data)->
								done(err,data)
								return contentCreate.reject(err) if err?
								contentCreate.resolve(ContentFacade.createClientDocument({content:content,data:final_data}))
					#TODO implement the sync logic
					addContent:(data,options,cb)->
						if _.isUndefined(cb)
							cb = options
							options = {}
						options = _.extend
							parent:null
							force_content_id:null
							args:null
						,options
						contentCreate = _when.defer()
						contentCreate.promise.then (reply)->
							cb null,reply
						,(error)->
							cb error,null
						content_options =
							id:options.force_content_id||null
							content_type: if !options.content_sub_type then app.contentType else app.contentType+":"+options.content_sub_type
							ref_content:options.parent
							notify_ui:false
							emit_network:true
							read:true
							args:options.args
						content_lib.addContent place_id,content_options,(err,content,done)->
							return contentCreate.reject(err) if err?
							data.content_id = content.id #link the content with the data part
							app.module.crud.create context,content,data,options.crud_options||null,(err,final_data)->
								done(err,data)
								return contentCreate.reject(err) if err?
								contentCreate.resolve(ContentFacade.createClientDocument({content:content,data:final_data}))
					updateContent:(content_id,attrs,options,cb)->
						if _.isUndefined(cb)
							cb = options
							options = {}
						options = _.extend
							args:null
							crud_options: null
						,options
						content_options=
							downloaded:true
							uploaded:false
							id:content_id
							args:options.args
							emit_network:true
							read:true
						content_lib.updateContent place_id,content_options,(err,content,done)->
							app.module.crud.update context,content_id,attrs,options.crud_option,(err,new_data)->
								done(err,new_data)
								cb err,ContentFacade.createClientDocument({content:content,data:new_data})

					addContentAutoReply:(data,options,res)->
						if _.isUndefined(res)
							res = options
							options = {}
						@addContent data,options,(err,data)->
							res.send {err:err,data:data}

					deleteContent:(content_id,cb)->
						async.waterfall [
							(callback)->
								content_lib.getContentById place_id,content_id,{raw:true,unmarshall:false},callback
							(content,callback)->
								app.crud.delete context,content_id,(err)->
									callback err,content==null
							(content,callback)->
								content_lib.deleteContent place_id,{id:content_id,emit_network:true},(err,done)->
									done(err==null)
									callback err,content
						],cb
				context.utils = utils
				#file storage path for applications who manage files
				if app?.file_storage == true
					place_lib.generateFolderNameFromPlaceId place_id,(err,folder_name)->
						return context_ready.reject(err) if err?
						context.file_dir = path.join app.file_dir_path,folder_name
						unless fs.existsSync context.file_dir
							mkdirp.sync context.file_dir,'0755'
						context_ready.resolve(context)
				else context_ready.resolve(context)
		else
			return cb null,cache[key]

	#############################################################################################
	############################# APPLICATION HTTP API MANAGEMENT ###############################
	#############################################################################################
	http_prefix = "#{server.url_prefix.app_api}/router"
	router = 
		withNamespace:(app_name)->
			return {
				on:(method,route,cbs...)->
					delegateApplication = (req,res)->
						i = 0
						next = ->
							return if i == cbs.length
							cbs[++i] req,res,next
						cbs[i] req,res,next
					express[method] "#{http_prefix}/#{app_name}#{route}",delegateApplication
					express[method] "#{http_prefix}/#{app_name}/places/:place_id#{route}",(req,res)->
						place_id = req.param 'place_id'
						async.waterfall [
							(callback)->
								#check if the place exists
								place_lib.getPlace place_id,callback
							(place,callback)->
								callback(new Error("Place not exists"),null) if place==null
								contextForApp app_name,place_id,callback
						],(err,context)->
							if err == null
								#add context to the request object
								req._ansamb_context = context
								delegateApplication(req,res)
							else
								res.send {err:err}
				static:(route,relative_path)->
					r = route
					if r[r.length-1]!="/" and r[r.length-1]!="/*"
						r += "/*"
					else if r[r.length-1]!="*"
						r += "*"
					app_path = application_registery.getAppByName(app_name).path
					express.get "/application/static/"+app_name+r,server.static_middleware(route,path.join(app_path,relative_path))
			}

	#############################################################################################
	################################## APPLICATION LOADING ######################################
	#############################################################################################
	#retrieve all places to update each database if required
	api = {}
	place_lib.getAllPlace null,{raw:true},(err,places)->
		if err
			return register err,null

		specialContentManager = new SpecialContentManager(db_manager)
		api.crud = 
			create:(place_id,content,data,cb)->
				console.log "Trying to handle content type #{content.content_type}"
				app = application_registery.getApplicationForContentType(content.content_type)
				if typeof app == 'undefined'
					console.log "No application can handle this type of file"
					return cb new Error("No application to handle content type:#{content.content_type}")
				#create context
				context = contextForApp app.name,place_id,(err,context)->
					data.id = content.id
					app.module.crud.create context,content,data,null,cb
			read:(place_id,content,cb)->
				app = application_registery.getApplicationForContentType(content.content_type)
				if typeof app == 'undefined'
					console.log "No application can handle this type of file"
					return cb new Error("No application to handle content type:#{content.content_type}")
				#create context
				context = contextForApp app.name,place_id,(err,context)->
					app.module.crud.read context,content.id,cb
			read_protocol:(place_id,content,cb)->
				app = application_registery.getApplicationForContentType(content.content_type)
				if typeof app == 'undefined'
					console.log "No application can handle this type of file"
					return cb new Error("No application to handle content type:#{content.content_type}")
				#create context
				context = contextForApp app.name,place_id,(err,context)->
					app.module.crud.read_protocol context,content.id,cb
			update:(place_id,content,new_data,cb)->
				app = application_registery.getApplicationForContentType(content.content_type)
				if typeof app == 'undefined'
					console.log "No application can handle this type of file"
					return cb new Error("No application to handle content type:#{content.content_type}")
				context = contextForApp app.name,place_id,(err,context)->
					app.module.crud.update context,content.id,new_data,null,cb
			delete:(place_id,content,cb)->
				app = application_registery.getApplicationForContentType(content.content_type)
				if typeof app == 'undefined'
					return cb new Error("No application to handle content type:#{content.content_type}")
				context = contextForApp app.name,place_id,(err,context)->
					app.module.crud.delete context,content.id,cb
			# options = {new_relative_path:string,transaction:sequelize_transaction,network_promise:_when.promise}
			rename:(place_id,content,options,cb)->
				app = application_registery.getApplicationForContentType(content.content_type)
				if typeof app == 'undefined'
					return cb new Error("No application to handle content type:#{content.content_type}")
				context = contextForApp app.name,place_id,(err,context)->
					app.module.crud.rename context,content.id,options,cb
		#add the specialContentManager behaviour to each crud methods
		specialContentManager.addBehaviourToCrud api.crud

		#cache management
		place_lib.on 'place:delete',(place_id)->
			#we need to delete all context related to this place id
			for application of application_registery.getApplications()
				console.log "delete context cache for place #{place_id}, #{application}"
				delete cache[buildCacheKey(application,place_id)]

		#init all applications before registering plugin
		applications = _.values application_registery.getApplications()
		list_places = _.map places,(p)->p.id

		async.each applications,(application,callback)->
			application_registery.initApplication application.name,router.withNamespace(application.name),db_manager,list_places,callback
			#automatic route handling to serve application static content within a place
			if application?.file_storage==true
				url = "#{http_prefix}/#{application.name}/places/:place_id/files/:file_name"
				express.get url,(req,res)->
					place_id = req.param 'place_id'
					relative_path = decodeURIComponent(req.param 'file_name')
					return res.send(403) if /(\/|^)\.\.(\/|$)/.test(relative_path)
					place_lib.generateFolderNameFromPlaceId place_id,(err,place_folder_name)->
						return res.send 404 if err? or place_folder_name==null
						p = path.join application.file_dir_path,place_folder_name,relative_path
						res.sendfile(p)
		,(err)->
			console.log err if err?
			register err,
				"application.broker":{api:api}
