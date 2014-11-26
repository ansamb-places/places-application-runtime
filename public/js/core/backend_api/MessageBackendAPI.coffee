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
define ->
	return {
		sendMessage:(content_type,place_id,dst,payload)->
			done = $.Deferred()
			request =
				type: 'POST'
				url: "/core/api/v1/message/#{content_type}/?place_name=#{place_id}&dst=#{dst}"
				data: JSON.stringify(payload)
				dataType: "json"
				contentType: "application/json"
				processData: false
			$.ajax request
			.done (reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.ok)
			.fail ->
				done.reject "Request error"
			return done.promise()
	}