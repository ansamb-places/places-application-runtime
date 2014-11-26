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
		getNotifications:->
			done = $.Deferred()
			$.get "/core/api/v1/notifications/",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.data)
			.fail ->
				done.reject "Request error"
			return done.promise()
		markAsRead:(id)->
			done = $.Deferred()
			end_url = if not _.isUndefined(id) then "?id=#{id}" else ""
			$.get "/core/api/v1/notifications/mark_read#{end_url}",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.ok)
			.fail ->
				done.reject "Request error"
			return done.promise()
	}