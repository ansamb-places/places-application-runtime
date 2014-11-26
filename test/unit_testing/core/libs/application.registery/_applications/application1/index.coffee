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
module.exports =
	init:(router)->
		router.on('get','/',api.handleGet)
		router.on('post','/',api.handlePost)
		router.static('/public/','public')
	crud:
		create:(context,content,data,options,cb)->
			db_data =
				content_id:data.content_id
				name:data.relative_path.substr data.relative_path.lastIndexOf('/')+1
				filesize:data.filesize
				mdate:data.mdate
				relative_path:data.relative_path
				mime_type:data.mime_type
			context.database.models.file.create(db_data).done (err,file)->
				return cb err,file?.values
		read:(context,content_id,cb)->
			context.database.models.file.find({where:{content_id:content_id}},{raw:true}).done cb
		read_protocol:(context,content_id,cb)->
			context.database.models.file.find({where:{content_id:content_id}},{raw:true}).done (err,data)->
				return cb err,null if err?
				cb null,_.pick(data,'relative_path','filesize','mime_type','mdate')
		update:(context,content_id,new_data,options,cb)->
			context.database.models.file.update(new_data,{content_id:content_id}).done (err)->
				cb err,new_data
		delete:(context,content_id,cb)->
			context.database.models.file.destroy({where:{content_id:content_id}}).done cb
api =
	handleGet:(req,res)->
		res.send "ok"
	handlePost:(req,res)->
		res.send req.body