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

require_context = (req,res,next)->
	if _.isUndefined req._ansamb_context
		return res.send {err:"no ansamb context found"}
	next()

module.exports = 
	init:(router)->
		router.on 'get','/content/:content_id',require_context,(req,res)->
			api.getPost req._ansamb_context,req.param('content_id'),(err,posts)->
				res.send {err:err,data:posts}
		router.on 'post','/',require_context,(req,res)->
			context = req._ansamb_context
			return console.error "No context defined"if _.isUndefined context
			context.content_lib.addContentAutoReply req.body,res
		router.static('/public/','public')
	handleMessage:(app_data,context,cb)->
		console.log "application post receive a message"
	crud:
		create:(context,content,data,options,cb)->
			data.id = content.id
			context.database.models.post.create(data).done (err,post)->
				return cb err,null if err?
				cb err,post.values
		read:(context,id,cb)->
			context.database.models.post.find({where:{id:id}},{raw:true}).done cb
		read_protocol:(context,id,cb)->
			context.database.models.post.find({where:{id:id}},{raw:true}).done cb
		update:(context,id,new_data,options,cb)->
			delete new_data.id #we don't want the data id to be modified
			context.database.models.post.update(new_data,{id:id}).done (err)->
				cb err,new_data
		delete:(context,id,cb)->
			context.database.models.post.destroy({id:id}).done cb
api = 
	getPost:(context,id,cb)->
		context.database.models.post.find({where:{id:id}},{raw:true}).done cb
	newPost:(context,post,cb)->
		context.content_lib.addContentAutoReply (err,content,done)->
			return cb err,null if err?
			context.database.models.post.create(post).done (err,post)->
				cb err,null if err?
				post.setContent(content).done (err)->
					cb err,{content:content.values,data:post.values}
