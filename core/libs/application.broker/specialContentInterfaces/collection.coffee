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
	name:'collection'
	crud:
		create:(database,content,data,options,cb)->
			data.content_id = content.id
			database.models.global.content.update({_app_children_type:data.app_children_type},{id:content.id}).done (err,d)->
				cb err,data
		read:(database,content,cb)->
			cb null,{app_children_type:content._app_children_type}
		update:(database,content,data,options,cb)->
			database.models.global.content.update(
				{_app_children_type:data.app_children_type}
				{id:content.id}
			).done (err,d)->
				cb err,data
		delete:(database,content,cb)->
			cb null,true