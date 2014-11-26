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
define [],->
	class Conversation extends Backbone.NestedModel
		defaults:
			last_content:null
			ansambers:[]
	class Conversations extends Backbone.Collection
		model:Conversation
		url: '/core/api/v1/places/helper/place_with_last_content/?type=conversation&ansambers=1'
		comparator:(item1,item2)->
			## sort correctly the collection
			lt1 = item1.get('last_content')
			lt2 = item2.get('last_content')
			## all null content are placed on bottom
			return 0 if (lt1 == null and lt2 == null)
			return 1 if lt1 == null
			return -1 if lt2 == null
			lt1 = lt1.date 
			lt2 = lt2.date 
			## younger content conversation are moved in first pos to be rendered in first
			return -1  if lt1 > lt2	
			return 1 if lt2 > lt1	 
			return 0 
		parse:(response,options)->
			return response.data||[]
	conv_coll = new Conversations
	conv_coll.fetch()
	return conv_coll