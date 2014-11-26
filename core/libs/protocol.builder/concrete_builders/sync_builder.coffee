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
# the sync protocol allow to retrieve modifications made on a place while we were disconnecting
# and to send modifications made while we were offline
common =
	protocol:"sync"
	ver:"1"
module.exports =
	name:'sync'
	api:
		enableSyncForPlace:(data)->
			_.defaults data,{reset:false}
			data.reset = !!data.reset
			message:
				_.extend {
					method:"ENABLE_RT_RCPT"
					spl:data.place_id
					dpl:data.place_id
					data:
						channel:data.channel||"default"
						reset:data.reset
				},common
			_conditions:['server_link:connected'] #theses conditions have to be satisfied before sending the message
		disableSyncForPlace:(data)->
			_.extend {
				method:"DISABLE_RT_RCPT"
				spl:data?.place_id||"*"
				dpl:data?.place_id||"*"
			},common
		get:(data)->
			msg = _.extend {
				method:"GET"
				spl:data.place_id
				dpl:data.place_id
				data:
					content_id:data.content_id
			},common
			msg.data.max_contents_per_msg = data.max_contents_per_msg if not _.isUndefined data.max_contents_per_msg
			return msg
		put:(data)->
			_.extend {
				method:"PUT"
				data:
					content:data.content||null
					base_version:data.base_version||null
			},common
		delete:(data)->
			_.extend {
				method:"DELETE"
				data:
					content:data.content_id||null
					base_version:data.base_version|null
			},common