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
path = require 'path'
_when = require 'when'
fs = require 'fs'
request = require 'request'
#the following middleware will just check if the place_name is here
require_place_name = require("../../common_lib/express_middlewares").require_place_name
require_place_id = require("../../common_lib/express_middlewares").require_place_id
require_status = require("../../common_lib/express_middlewares").require_status
ContentFacade = require '../../common_lib/ContentFacade'


module.exports = (options,imports,register)->
	server = imports.server
	express = server.app
	content_manager = imports.content_manager
	application_broker = imports["application.broker"]
	application_registery = imports["application.registery"]
	place_lib = imports["api.place"]
	ansamber_lib = imports["api.place.ansamber"]
	account_lib = imports["api.account"]
	protocol_builder = imports["protocol.builder"]
	external_service_manager = imports["external_service_manager"]
	events = imports["events"]

	#private functions
	mergeContent = (object)->
		#special merge strategy which will move some data from content to data field
		ret = {}
		content = object.content
		data = object.data
		children = object.children
		if content.ansamb_extras?
			ansamb_extras = content.ansamb_extras
			ret.content = _.omit content,'ansamb_extras'
			ret.data = _.extend data||{},{ansamb_extras:ansamb_extras}
		else #nothing special to do
			ret =
				content:content
				data:data
		ret.children = children if children?
		return ret

	api = 
		#the difference with the method of content_manager is that
		#this one is going to retrieve also datas from applications
		#and not only from the global content table
		getContentForPlace:(place_id,depth,cb)->
			if _.isUndefined cb
				cb = depth
				depth =2
			place_lib.checkPlace place_id,(exists)->
				if exists==false
					return cb(new Error("Place does not exist"))
				api._getContentsWithFilter place_id,{ref_content:null},depth,cb
		getContentById:(place_id,content_id,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {}
			async.waterfall [
				(callback)->
					content_manager.getContentById place_id,content_id,options,callback
				(content,callback)->
					return callback "Content not found" if content==null
					application_broker.api.crud.read place_id,content,(err,app_data)->
						return callback err,null if err?
						if options.raw==true
							callback err,{content:content,data:app_data}
						else
							callback err,ContentFacade.createClientDocument({content:content,data:app_data})
			],cb
		countContentForPlace:(place_id,filter,cb)->
			filter = filter||{}
			content_manager.countContent place_id,filter,cb
		_getContentsWithFilter:(place_id,filter,max_depth,cb)->
			content_manager._getContentsWithFilter place_id,filter,{raw:true},(err,contents)->
				return cb(err,null) if err?
				return cb null,[] if contents==null #no contents
				async.mapSeries contents,(content,callback)->
					async.parallel
						content:(_callback)->
							_callback(null,content)
						owner:(_callback)->
							ansamber_lib.getAnsamberOfPlace place_id,content.owner,_callback
						#let's ask the application the datas associated with the content
						data:(_callback)->
							application_broker.api.crud.read place_id,content,(err,app_data)->
								return _callback err,null if err?
								_callback err,app_data
						children:(_callback)->
							return _callback null,[] if max_depth<=0
							api._getContentsWithFilter place_id,{ref_content:content.id},max_depth-1,_callback
					,(err,results)->
						callback err,ContentFacade.createClientDocument(results)
				,cb
		getLastContentForPlace:(place_id,cb)->
			async.waterfall [
				(callback)->
					content_manager._getcontentWithFilterAndOrder place_id,{ref_content:null},'date DESC',{raw:true},callback
				(content,callback)->
					return callback null,null if content==null
					application_broker.api.crud.read place_id,content,(err,app_data)->
						callback err,ContentFacade.createClientDocument({content:content,data:app_data})
			],cb
		getLastContentFromOtherForPlace:(place_id,cb)->
			async.waterfall [
				(callback)->
					filter =
						ref_content:null
						owner:{ne:null}
					content_manager._getcontentWithFilterAndOrder place_id,filter,'date DESC',{raw:true},callback
				(content,callback)->
					return callback null,null if content==null
					application_broker.api.crud.read place_id,content,(err,app_data)->
						callback err,ContentFacade.createClientDocument({content:content,data:app_data})
			],cb
		_addContentToPlace:(place_id,content_options,data,cb)->
			#assume that contents coming from the network are not downloaded yet
			content_options.downloaded = content_options.downloaded ? false
			async.waterfall [
				(callback)->
					content_manager.addContent place_id,content_options,callback
				(content,done,callback)->
					ansamber_lib.getAnsamberOfPlace place_id,content.owner,(err,owner)->
						callback err,content,done,owner
				(content,done,owner,callback)->
					application_broker.api.crud.create place_id,content,data,(err,final_data)->
						done err,final_data,owner
						callback err,content,final_data
						#auto download content
						# api.downloadContent place_id,content.id,(err)->
						# 	console.log "DOWNLOAD ERROR:",err if err?
			],cb
		_updateContentOfPlace:(place_id,content_options,data,cb)->
			content_options.force = content_options.force ? false
			content_options.downloaded = false
			merge_algo = content_options.merge_algo||"lastest_win"
			if merge_algo=="latest_win"
				async.waterfall [
					(callback)->
						content_manager.getContentById place_id,content_options.id,callback
					(old_content,callback)->
						return callback("Content not found",null) if old_content==null
						if (old_content.date<content_options.date and content_options.rev!=old_content.rev) or content_options.force==true
							async.waterfall [
								(_callback)->
									content_manager.updateContent place_id,content_options,_callback
								(content,done,_callback)->
									ansamber_lib.getAnsamberOfPlace place_id,content.owner,(err,owner)->
										_callback err,content,done,owner
								(content,done,owner,_callback)->
									application_broker.api.crud.update place_id,content,data,(err,final_data)->
										done err,final_data,owner
										_callback err,content,final_data
							],callback
						else
							callback "The local version is already up-to-date"
				],cb
			else
				cb "Unknow merge algorithm"
		#content_options = {id:string,emit_network:boolean}
		_deleteContentOfPlace:(place_id,content_options,cb)->
			async.waterfall [
				(callback)->
					content_manager.getContentById place_id,content_options.id,{raw:true,unmarshall:false},callback
				(content,callback)->
					application_broker.api.crud.delete place_id,content,(err)->
						callback err
				(callback)->
					content_manager.deleteContent place_id,content_options,(err,done)->
						done(err==null)
						callback err,err==null
			],cb
		createOrUpdateContent:(place_id,content_options,data,cb)->
			async.waterfall [
				(callback)->
					content_manager.checkContent place_id,content_options.id,callback
				(content_exists,callback)->
					if content_exists==true
						api._updateContentOfPlace place_id,content_options,data,callback
					else
						api._addContentToPlace place_id,content_options,data,callback
			],cb
		copyContent:(spl,dpl,content_id,cb)->
			async.waterfall [
				(callback)->
					place_lib.checkPlace dpl,callback
				(existed,callback)->
					return callback "Destination place not found" if existed==false
					api.getContentById spl,content_id,{raw:true,unmarshall:true},callback
				#object have properties content and data
				(object,callback)->
					#the ansamb_extra field will be regenerated by the kernel
					delete object.content.ansamb_extras
					object.content = _.extend object.content,{
						read:true
						downloaded:true
						uploaded:false
						owner:null
						date:new Date()
						emit_network:true
						notify_ui:false
						id:if object.content.content_type!="file" then null else object.content.id
					}
					_when.promise (resolve,reject)->
						content_type = object.content.content_type
						switch content_type
							when "file"
								rp = object.data.relative_path
								async.parallel
									src:(_callback)->
										api.generateAbsoluteFilePath spl,{relative_path:rp,content_type:content_type},_callback
									dst:(_callback)->
										api.generateAbsoluteFilePath dpl,{relative_path:rp,content_type:content_type},_callback
								,(err,folders)->
									return reject err if err?
									return reject "Already Existing file" if fs.existsSync(folders.dst)
									object.content.args = {local_uri:"file://#{folders.dst}"}
									readstream = fs.createReadStream(folders.src)
									writestream = fs.createWriteStream(folders.dst)
									writestream.on "error",(error)->
										return reject error
									writestream.on "finish",->
										resolve()
									readstream.on "error",(error)->
										reject error
									try
										readstream.pipe(writestream)
									catch e
										reject e
							else
								resolve()
					.done ->
						api._addContentToPlace dpl,object.content,object.data,callback
					,(error)->
						callback error
			],cb
		renameFileContent:(place_id,options,cb)->
			network_promise = _when.defer()
			async.waterfall [
				(callback)->
					content_manager.getContentById place_id,options.old_content_id,{unmarshall:false},callback
				(c,callback)->
					crud_options =
						new_name:options.new_name
						new_relative_path:options.new_relative_path
						network_promise:network_promise.promise
					application_broker.api.crud.rename place_id,c,crud_options,(err,app_options)->
						callback err,c,app_options
				(c,app_options,callback)->
					content_manager_options = _.extend options,
						network_promise:network_promise
						app_options:app_options
						content_type: options.content_type ? "file"
					content_manager.renameFileContent place_id,content_manager_options,(err)->
						callback err,app_options
			],(err,app_options)->
				cb and cb err,app_options
		addComment:(place_id,parent_id,comment,cb)->
			content_options =
				ref_content:parent_id
				content_type:'comment'
				emit_network:true
			data =
				by:null
				comment:comment
			api._addContentToPlace place_id,content_options,data,cb
		createCollection:(place_id,app_children_type,cb)->
			content_options =
				content_type:'collection'
				emit_network:true
			data =
				app_children_type:app_children_type
			api._addContentToPlace place_id,content_options,data,cb

		#special methods which can be used only with file content
		downloadContent:(place_id,content_id,cb)->
			async.waterfall [
				(callback)->
					api.getContentById place_id,content_id,{raw:true,unmarshall:true},callback
				(document,callback)->
					return callback "This content is not a downloadable one" if not document.content.downloadable
					return callback "Content already downloaded" if document.content.downloaded
					if not _.isObject(document.content.ansamb_extras) or _.isUndefined(document.content.ansamb_extras.uri)
						return callback "Missing informations"
					app_path = application_registery.getPathForContentType(document.content.content_type)
					return callback "No application to manage #{document.content.content_type}" if app_path==null
					api.generateAbsoluteFilePath place_id
							,{relative_path:document.data.relative_path,content_type:document.content.content_type},(err,p)->
						return callback err if err?
						local_uri = "file://#{p}"
						callback null,{ansamb_extras:document.content.ansamb_extras,local_uri:local_uri}
				(options,callback)->
					protocol_builder.file.downloadRequest({
						place:place_id
						content_id:content_id
						args:{local_uri:options.local_uri}
						ansamb_extras:options.ansamb_extras
					}).send (err,reply)->
						callback(err,reply)
				(reply,callback)->
					if reply.code!=200
						console.log "Error on starting download"
					callback null
			],cb
		streamContentTo:(place_id,content_id,dstStream,srcStream,cb)->
			api.getContentById place_id,content_id,{raw:true,unmarshall:true},(err,document)->
				return cb err.message||err if err?
				return cb "This is not a stream" if document.content.content_type != "file:stream"
				if not _.isObject(document.content.ansamb_extras) or _.isUndefined(document.content.ansamb_extras.uri)
					return cb "Missing informations"
				req_options =
					uri:document.content.ansamb_extras.uri
					method:'GET'
					strictSSL:false
					auth:
						user:document.content.ansamb_extras?.auth?.login || ""
						pass:document.content.ansamb_extras?.auth?.password || ""
						sendImmediately:true
				reqst=request(req_options)
				reqst.on 'error',->
					dstStream.end()
				reqst.on 'response',(resp)->
					headers=_.extend resp.headers,{'content-type':document.data.mime_type}
					dstStream.status(206)
					dstStream.set(headers)
					resp.on "data",(data)->
						dstStream.write(data)
					resp.on 'end',()->
						dstStream.end()
					resp.on 'error',->
						dstStream.end()
				srcStream.pipe(reqst)
				cb null
		#options = {relative_path:string,content_type:string}
		generateAbsoluteFilePath:(place_id,options,cb)->
			if arguments.length!=3
				return cb "Wrong call"
			return cb "Invalid options" if _.isUndefined(options.relative_path) or _.isUndefined(options.content_type)
			app_path = application_registery.getPathForContentType(options.content_type)
			return cb "No path for content type #{options.content_type}" if not app_path?
			place_lib.generateFolderNameFromPlaceId place_id,(err,place_folder_path)->
				return cb err if err?
				return cb null,path.join(app_path,place_folder_path,options.relative_path)
		getFileAbsolutePath:(place_id,content_id,cb)->
			async.waterfall [
				(callback)->
					api.getContentById place_id,content_id,{raw:true},callback
				(document,callback)->
					return callback "The content is not a file" if document.content.content_type != "file"
					options =
						content_type:document.content.content_type
						relative_path:document.data.relative_path
					api.generateAbsoluteFilePath place_id,options,callback
			],(err,p)->
				return cb err if err?
				fs.exists p,(exists)->
					if exists
						cb null,p
					else
						cb "The file does not exist"
		userDownloadFile:(place_id, content_id, download_path,cb)->
			api.getFileAbsolutePath place_id, content_id, (err, source_path)->
				if err?
					cb(err, false) 
				else
					api.fileCopy source_path, download_path, (error)->
						cb(error, true)
		fileCopy:(src_path,dst_path,cb)->
			read_stream = fs.createReadStream(src_path)
			read_stream.on 'error', (error)->
				console.log "readStream",error
				cb error
			write_stream = fs.createWriteStream(dst_path)
			write_stream.on 'error', (error)->
				console.log "WriteStream",error
				cb error
			write_stream.on 'finish', (error)->
				cb null
			read_stream.pipe(write_stream)
		handleDownloadEnd:(place_id,content_id,cb)->
			async.waterfall [
				(callback)->
					content_manager.getContentById place_id,content_id,{unmarshall:false},callback
				(content,callback)->
					if content == null
						return callback "Content not found"
					else
						content.updateAttributes({
							downloaded:true
						}).done callback
			],(err)->
				if err==null
					events.emitter.emit "download:end",place_id,content_id
				cb and cb err
		handleUploadEnd:(place_id,content_id,cb)->
			async.waterfall [
				(callback)->
					content_manager.getContentById place_id,content_id,{unmarshall:false},callback
				(content,callback)->
					return callback("content not found") if content == null
					content.updateAttributes({
						uploaded:true
					}).done callback
			],(err)->
				if err==null
					events.emitter.emit "upload:end",place_id,content_id
				cb and cb err
		resendPut:(place_id,content_id,cb)->
			async.waterfall [
				(callback)->
					content_manager.getContentById place_id,content_id,callback
				(content,callback)->
					application_broker.api.crud.read_protocol place_id,content,(err,data)->
						callback err,content,data
				(content,data,callback)->
					if content.content_type=='file'
						api.generateAbsoluteFilePath place_id
								,{relative_path:data.relative_path,content_type:content.content_type},(err,absolute_p)->
							return callback err if err? 
							local_uri = "file://#{absolute_p}"
							callback null,content,data,{local_uri:local_uri}
					else
						callback null,content,data,null
			],(err,content,data,args)->
				return cb err,null if err?
				obj =
					place:place_id
					dst:'*'
					content_id:content.id
					content_type:content.content_type
					date:content.date
					rev:content.rev
					ref_content:content.ref_content
					data:data
					ansamb_extras:content.ansamb_extras
				obj.args = args if args?
				protocol_builder.content.putRequest(obj).send()
				cb err,true

	###	
		HTTP API
	###

	prefix = server.url_prefix.core_api+'/places'
	rest_prefix = "#{prefix}/:place_id/contents"

	express.get "#{rest_prefix}/",
		require_place_id,
		(req,res)->
			api.getContentForPlace req.place_id,(err,contents)->
				err = err.toString() if err instanceof Error
				res.send {err:err,data:contents}

	express.post "#{rest_prefix}", require_place_id, (req,res) ->
		#TODO
		res.send {err:null}

	express.delete "#{rest_prefix}/", require_place_id, (req,res) ->
		#TODO
		res.send()

	express.get "#{rest_prefix}/_count",require_place_id,(req,res)->
		filter = {}
		filter.read = parseInt(req.query.read) if req.query.read and /^[0|1]$/.test(req.query.read)
		api.countContentForPlace req.place_id,filter,(err,count)->
			err = err.toString() if err instanceof Error
			res.send {err:err,data:count}

	express.get "#{rest_prefix}/_last",require_place_id,(req,res)->
		api.getLastContentForPlace req.place_id,(err,content)->
			err = err.toString() if err instanceof Error
			res.send {err:err,data:content}

	express.get "#{rest_prefix}/mark_as/:status", require_place_id, require_status, (req,res)->
		content_manager.markContentAs req.place_id,null,req.status,(err)->
			res.send {err:err}

	# NOT REST compliant API kept for compatibility reasons
	# ------------------------------------------------------
	express.post "#{prefix}/collection/",require_place_name,(req,res)->
		place_id = req.query.place_name
		app_children_type = req.body.app_children_type
		if not _.isString(app_children_type) or application_registery.getAllContentTypes().indexOf(app_children_type)==-1
			return res.send {err:"Invalid children type"}
		api.createCollection place_id,app_children_type,(err,content,data)->
			res.send {err:err,content:content,data:data}

		# NOT REST compliant API kept for compatibility reasons
	# ------------------------------------------------------
	express.get "#{prefix}/put/:content_id",require_place_name,(req,res)->
		place_id = req.place_name
		content_id = req.param 'content_id'
		api.resendPut place_id,content_id,(err,ok)->
			res.send {err:err,ok:ok}

	express.get "#{rest_prefix}/:content_id", require_place_id, (req,res) ->
		content_id = req.param 'content_id' 
		api.getContentById req.place_id,content_id,(err, content)->
			res.send {err:err, data:content}

	express.delete "#{rest_prefix}/:content_id", require_place_id, (req,res) ->
		content_options =
			id:req.param "content_id"
			emit_network:true
		api._deleteContentOfPlace req.place_id,content_options,(err,deleted)->
			res.send {err:err,deleted:deleted}

	express.post "#{rest_prefix}/:content_id", require_place_id, (req, res) ->
		content_id = req.param 'content_id'
		api.resendPut req.place_id,content_id,(err,ok)->
			res.send {err:err,ok:ok}

	express.get "#{rest_prefix}/:content_id/stream",require_place_id,(req,res)->
		api.streamContentTo req.place_id,req.param("content_id"),res,req,(err)->
			res.send err if err?

	express.post "#{rest_prefix}/:content_id/rename",require_place_id,(req,res)->
		content_id= req.param 'content_id'
		new_name= req.body_sanitized.new_name
		place_id= req.place_id
		if "string" isnt typeof new_name or new_name == ""
			return res.send {err:"New name missing or empty",data:null}
		api.renameFileContent place_id,{old_content_id:content_id,new_name:new_name,emit_network:true},(err,update)->
			res.send {err:err,data:update}

	express.get "#{rest_prefix}/:content_id/download",require_place_id,(req,res)->
		place_id = req.place_id
		content_id = req.param 'content_id'
		api.downloadContent place_id,content_id,(err)->
			res.send {err:err}

	express.post "#{rest_prefix}/:content_id/copy",require_place_id,(req,res)->
		spl = req.place_id
		dpl = req.body.dpl
		content_id = req.param("content_id")
		if "string" isnt typeof dpl or dpl == ""
			return res.send {err:"dpl parameter is missing or invalid",data:null}
		api.copyContent spl,dpl,content_id,(err,content,data)->
			_data = null
			if err==null
				_data = ContentFacade.createClientDocument({content:content,data:data})
			res.send {err:err,data:_data}

	express.get "#{rest_prefix}/:content_id/mark_as/:status", require_place_id, require_status, (req,res)->
		content_id = req.param('content_id')
		content_manager.markContentAs req.place_id,content_id,req.status,(err)->
			res.send {err:err}

	express.get "#{rest_prefix}/:content_id/info/path",require_place_id,(req,res)->
		place_id = req.place_id
		content_id = req.param('content_id')
		api.getFileAbsolutePath place_id,content_id,(err,path)->
			return res.send {err:err,path:path}

	express.post "#{rest_prefix}/:content_id/user_download",require_place_id,(req,res)->
		place_id = req.place_id
		content_id = req.param('content_id')
		download_path = req.body["download_path"]
		return res.send {err:"Invalid path",ok:false} if not _.isString(download_path) or download_path?.length == 0
		api.userDownloadFile place_id, content_id, download_path, (err,ok)->
			res.send {err:err,ok:ok}

	register null,{"api.place.content":api}
