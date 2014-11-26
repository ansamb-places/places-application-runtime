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
#this application is not a valid one because the init method is missing

module.exports = 
	crud:
		create:(context,content,data,options,cb)->
			data.content_id = content.id
			context.database.models.post.create(data).done (err,post)->
				return cb err,null if err?
				cb err,post.values
		read:(context,content_id,cb)->
			context.database.models.post.find({where:{content_id:content_id}},{raw:true}).done cb
		update:(context,content_id,new_data,options,cb)->
			context.database.models.post.update(new_data,{content_id:content_id}).done (err)->
				cb err,new_data
		delete:(context,content_id,cb)->
			context.database.models.post.destroy({where:{content_id:content_id}}).done cb