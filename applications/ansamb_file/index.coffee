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
fs = require('fs')
async = require 'async'
path = require 'path'
_ = require 'underscore'
_when = require 'when'
open = require 'open'
crypto = require 'crypto'
mkdirp = require 'mkdirp'
archiver = require 'archiver'
require 'when/monitor/console'
uuid = require 'node-uuid'
latinise = require './latinise.js'

require 'unorm' 

require_context = (req,res,next)->
	if _.isUndefined req._ansamb_context
		return res.send {err:"no ansamb context found"}
	next()

# normalizeName = (name)->
# 	latinise(name)

translate_re = /[éáűőúöüóíÉÁŰŐÚÖÜÓÍ]/g; 
translate = { "é": "e", "á": "a", "ű": "u", "ő": "o", "ú": "u", "ö": "o", "ü": "u", "ó": "o", "í": "i", "É": "E", "Á": "A", "Ű": "U", "Ő": "O", "Ú": "U", "Ö": "O", "Ü": "U", "Ó": "O", "Í": "I" };

normalizeName = (name) ->
	name.normalize().replace translate_re, (match) -> 
		translate[match]

module.exports =
	init:(router)->
		router.on('post','/',_.partial(api.fileUpload, {update:false}))
		router.on 'post','/open/', require_context,(req,res)->
			api.openContent req._ansamb_context,req.param('filename'),(err,file)->
					res.send {err:err,data:file}
		router.on('put','/',_.partial(api.fileUpload, {update:true})) 
		router.static('/public/','public')
		router.on 'get','/download/:content_id',require_context,(req,res)->
			api.downloadFile req,res
	crud:
		create:(context,content,data,options,cb)->
			db_data =
				id:content.id
				name:data.name
				filesize:data.filesize
				mdate:data.mdate
				relative_path:data.relative_path
				mime_type:data.mime_type
			context.database.models.file.create(db_data).done (err,file)->
				return cb err,file?.values
		read:(context,id,cb)->
			context.database.models.file.find({where:{id:id}},{raw:true}).done cb
		read_protocol:(context,id,cb)->
			context.database.models.file.find({where:{id:id}},{raw:true}).done (err,data)->
				return cb err,null if err?
				cb null,_.pick(data,'relative_path','filesize','mime_type','mdate', 'name')
		update:(context,id,new_data,options,cb)->
			@read context,id,(err,data)->
				return cb err if err?
				delete new_data.id #we don't want the data id to be modified
				_.extend data,new_data
				context.database.models.file.update(data,{id:id}).done (err)->
					cb err,data
		delete:(context,id,cb)->
			async.waterfall [
				(callback)=>
					@read context,id,callback
				(content,callback)->
					context.database.models.file.destroy({id:id}).done (err)->
						callback err,content
				(content,callback)->
					p = path.join(context.file_dir,content.relative_path)
					try
						if fs.existsSync p
							fs.unlinkSync p
					catch e
						return callback e
					callback null
			],cb
		rename:(context,id,options,cb)->
			new_name = options.new_name
			network_promise = options.network_promise
			@read context,id,(err,data)->
				return cb err if err?
				if options.new_relative_path?
					new_relative_path = options.new_relative_path
				else
					base_path = path.dirname(data.relative_path)
					new_relative_path = path.join(base_path,new_name)
				src = path.join(context.file_dir,data.relative_path)
				dst = path.join(context.file_dir,new_relative_path)
				args =
					local_uri:"file://#{dst}"
				sha = crypto.createHash('sha256')
				sha.update(new_relative_path,'utf8')
				new_id = sha.digest('hex')
				new_data=
					name:new_name
					relative_path:new_relative_path
				_.extend data,new_data
				context.database.models.file.find({where:{id:new_id}},{raw:true}).done (err,d)->
					return cb "file already exist",null if d
					context.database.models.file.update(data,{id:id}).done (err)->
						return cb err,data if err
						network_promise.done (renamed)->
							mkdirp.sync(path.dirname(dst)) if !fs.exists(path.dirname(dst))
							fs.rename src, dst,(err)->
								console.error "An error occured while renaming the file:",err if err?
								renamed(err)
						,(err)-> #nothing to do but the error callback is require to avoid bugs
						cb err,{new_content_id:new_id,relative_path:new_relative_path,name:new_name}
buildRandomName=(filename,context)->
	ext = context.utils.parseFileExt(filename)
	return uuid.v4()+ext
api =
	fileUpload:(options,req,res)->
		context = req._ansamb_context
		upload_place_Dir = context.file_dir
		if req.body.files? then files = req.body.files else files = [req.body]
		if typeof(req.body.randomize) == "string"
			switch req.body.randomize
				when "false"
					req.body.randomize=false
				when "true"
					req.body.randomize=true
		randomize = req.body.randomize
		collection= null

		async.waterfall [
			(callback)->
				if files.length>1
					context.content_lib.addCollection (err,place_collection)->
						callback err if err?
						callback null,place_collection
				else if files.length==1
					callback null,null
				else callback "empty files array"
			(place_collection, callback)->
				if place_collection?
					collection_path= path.join(upload_place_Dir,place_collection.id)
					fs.mkdir collection_path,(error)->
						callback error,place_collection,collection_path
				else
					callback null,place_collection,upload_place_Dir
			(place_collection,final_path,callback)->
				parent= place_collection?.id || null
				relative_path_dir = ""
				if place_collection?.id
					relative_path_dir = place_collection.id+'/'
				async.mapSeries files,(item,_callback)->
					is_dir = false
					if fs.statSync(item.path).isDirectory()
						is_dir = true
						archive = api.getArchiveName(item.name, upload_place_Dir)
						
						if randomize == true
							relative_path_file = buildRandomName(archive.name,context) 
						else
							relative_path_file = path.join(relative_path_dir,normalizeName(archive.name))
						dst = archive.path
					else
						if randomize == true
							relative_path_file = buildRandomName(item.name,context) 
						else
							relative_path_file = path.join(relative_path_dir,normalizeName(item.name))
						
						src = item.path
						dst = path.join(final_path,relative_path_file)

					_when.promise (resolve, reject)->
						if not fs.existsSync(dst) || options.update == true || randomize
							if is_dir
								api.uploadFolder(item, upload_place_Dir).done ->
									relative_path_file = path.join(relative_path_dir,item.name)
									src = item.path
									dst = path.join(final_path,item.name)
									resolve()
								,(err)->
									reject err
							else
								api.fileCopy src,dst,(error)->
									return reject error if error?
									resolve()
						else
							reject "already existing file"
					.done ->
						file =
							relative_path:relative_path_file
							filesize:item.size
							mime_type:item.type
							name:item.name
							mdate:new Date(item.lastModifiedDate)
						args =
							local_uri:"file://#{dst}"
						sha = crypto.createHash('sha256')
						sha.update(relative_path_file,'utf8')
						id = sha.digest('hex')
						local_options =
							parent:parent
							force_content_id: if options.update then null else id
							args:args
							crud_options:
								downloaded:true
						if options.update
							context.content_lib.updateContent id,file,local_options,_callback
						else
							context.content_lib.addContent file,local_options,_callback
					, (err)->
						_callback err
				,(err,result)->
					callback err,place_collection,result
		],(error,place_collection,result)->
			if error?
				res.send {err:error}
				return
			##build data object
			data= null
			if place_collection?
				data= place_collection
				data.children= result
			else 
				data= result[0]
			res.send {err:error,data:data}

	anyDir:(files)->
		return _.some files, (file)-> return fs.statSync(file.path).isDirectory()
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
			console.log "copy done"
			cb null
		read_stream.pipe(write_stream)
	getContent:(context,id,cb)->
		context.database.models.file.find({where:{id:id}},{raw:true}).done cb
	openContent:(context,filename,cb)->
		path_to_file = path.join(context.file_dir,filename)
		if fs.existsSync path_to_file
			open path_to_file
			cb null,filename
		else
			console.log  'error while opening a file'
			cb 'error while opening file',null
	downloadFile:(req,res)->
		context= req._ansamb_context
		id = req.param('content_id')
		context.database.models.file.find({where:{id:id}},{raw:true}).done (err,data)->
			path_to_file = path.join(context.file_dir,data.relative_path)
			if fs.existsSync path_to_file
				res.download path_to_file
			else
				console.log 'error while downloading a file'
				res.send {err:'unexisting file',data:null}
	filterItems:(files)->
		console.log files
		actual_files = []
		folders = []
		_.each files, (item)->
			if fs.statSync(item.path).isDirectory()
				folders.push item
			else
				actual_files.push item
		return {files:actual_files, folders:folders}

	uploadFolder:(folder, upload_place_Dir)->
		_when.promise (resolve, reject)->
			archive_name = folder.name + '.zip'
			archive_path = path.join(upload_place_Dir, archive_name)

			output = fs.createWriteStream(archive_path)
			archive = archiver 'zip'

			archive.on 'error', (err)->
				reject err

			output.on 'close', ()=>
				folder.name = archive_name
				folder.path = archive_path
				folder.size = archive.pointer()
				folder.type = "application/octet-stream"
				resolve()

			archive.pipe output

			archive.bulk 
				expand: true
				cwd: folder.path + '/'
				src: ['**/*']

			archive.finalize()

	getArchiveName:(name, upload_place_Dir)->
		return { name:name+".zip", path:path.join(upload_place_Dir, name+".zip")}


