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
#this protocol is used to create places and make operations onto them
#ex: profile
_ = require 'underscore'
common = 
	ver:1
	protocol:'place'
module.exports = 
	name:'place'
	api:
		addAnsamberRequest:(data)->
			return _.extend
				spl:data.place_uid
				dpl:data.place_uid
				dst:data.user_uid
				method:'ADD_ANSAMBER'
				data:
					id:data.place_id
					name:data.name
					desc:data.desc||""
					image_uri:null
					thumb_image_uri:null
					type:data.type
					protocols:null
					creation_date:data.creation_date
					owner_uid:data.owner_uid||""
					uid:data.place_uid
			,common
		addAnsamberReply:(data)->
			_.extend
				spl:data.place
				dpl:data.place
				dst:data.user_uid
				method:'ADD_ANSAMBER'
				ref_id:data.request_id
				code:if data.accepted==true then 200 else 470
				data:
					uid:data.place
			,common
		removeAnsamberRequest:(data)->
			return _.extend
				spl:data.place
				dpl:data.place
				dst:'*'
				method:'REMOVE_ANSAMBER'
				data:
					uid:data.user_uid
			,common
		placeCreateRequest:(data)->
			_.extend
				method:'CREATE'
				spl:'ansamb.places'
				dpl:'ansamb.places'
				data:
					id:data.id
					type:data.type
					owner_uid:data.owner_uid||''
					name:data.name||""
					desc:data.desc||null
					image_uri:data.image_uri|null
					thumb_image_uri:data.thumb_image_uri||null
					protocols:null
					creation_date:data.creation_date
					uid:data.uid
			,common
		deletePlace:(data)->
			_.extend
				method:'DELETE'
				spl:data.place
				dpl:data.place
			,common
		leavePlace:(data)->
			_.extend
				method:'LEAVE'
				spl:data.place
				dpl:data.place
			,common
		renamePlace:(data)->
			_.extend
				method:'RENAME'
				spl:data.place
				dpl:data.place
				data:
					name:data.name
			,common
		getBasicsDocuments:(data)->
			message:_.extend
				method:'GET_BASICS'
				dst:data.owner
				spl:data.place
				dpl:data.place
				,common
			_conditions:['server_link:connected']
