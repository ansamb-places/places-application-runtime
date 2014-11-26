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

module.exports = 
	init:(router)->
		router.on('get','/',api.handleRootRequest)
		router.on('get','/content/:contentId',api.getContent)
		router.static('/public/','public')
	handleMessage:(content,payload,context,cb)->
		console.log content
		context.database.models.myModels.my_content.create(
			payload
		).done (err,c)->
			args = arguments
			#create database association between global content and application content
			c.setContent(content).done (err)->
				console.log err if err
				cb.apply null,args

api = 
	handleRootRequest:(req,res)->
		res.send "ok from app2"
	getContent:(req,res)->
		content_id = req.param 'contentId'
		req._ansamb_context.database.models.myModels.my_content.find({where:{content_id:content_id}})
		.done (err,content)->
			res.send {err:err,data:content}
