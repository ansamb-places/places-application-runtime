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
fs = require 'fs'
common = 
	ver:1
	protocol:'contact'
	spl:'ansamb.contact'
	dpl:'ansamb.contact'
module.exports = 
	name:'contact'
	api:
		addContactRequest:(data)->
			message = _.extend
				method:'ADD'
				content_type:'message'
				dst:data.uid
				data:
					message:data.message
			,common
			return message
		addContactReply:(data)->
			message = _.extend
				method:'ADD'
				content_type:'message'
				dst:data.uid
				ref_id:data.ref_id
				code:if data.accepted==true then 200 else 470
				data:
					message:data.message
			,common
		removeContact:(data)->
			_.extend 
				method:'REMOVE'
				dst:data.uid
			,common
		checkContact:(data)->
			_.extend
				method:'EXISTS'
				dst:'ansamb'
				data:
					uid:data.uid
			,common
		syncStatus:->
			_.extend
				method:'SYNC_STATUS'
				dst:'ansamb'
			,common
		addNG:(data)->
			_.extend
				method:'ADD_NG'
				dst:data.uid
			,common
