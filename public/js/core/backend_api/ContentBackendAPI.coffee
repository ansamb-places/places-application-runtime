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
		markAllAsRead:(place_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/contents/mark_as/read",(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		markAsRead:(place_id,content_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/contents/#{content_id}/mark_as/read",(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		markAllAsUnRead:(place_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/contents/mark_as/unread",(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		markAsUnRead:(place_id,content_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/contents/#{content_id}/mark_as/unread",(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		downloadContent:(place_id,content_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/contents/#{content_id}/download",(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		deleteContent:(place_id,content_id)->
			done = $.Deferred()
			$.ajax 
				url:"/core/api/v1/places/#{place_id}/contents/#{content_id}"
				type:"DELETE"
			.done (response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve(response.deleted)
			.fail ->
				done.reject "Request error"
			return done.promise()
		copyContent:(source_place_id,destination_place_id,content_id)->
			done = $.Deferred()
			body =
				dpl:destination_place_id
			$.post "/core/api/v1/places/#{source_place_id}/contents/#{content_id}/copy",body,(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve(response.data)
			.fail ->
				done.reject "Request error"
			return done.promise()
		downloadFile:(place_id, content_id, download_path)->
			done = $.Deferred()
			$.post "/core/api/v1/places/#{place_id}/contents/#{content_id}/user_download",{download_path:download_path},(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve(response.path)
			.fail ->
				done.reject "Request error"
			return done.promise()
		renameFile:(place_id,content_id,new_name)->
			done = $.Deferred()
			$.post "/core/api/v1/places/#{place_id}/contents/#{content_id}/rename",{new_name:new_name},(response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve(response.data)
			.fail ->
				done.reject "Request error"
			return done.promise()
		getUnreadContent:(place_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/contents/_count?read=0", (response)->
				if response.err?
					console.log response.err
					done.reject response.err
				else
					done.resolve(response.data)
			.fail ->
				done.reject "Request error"
			return done.promise()
		getAbsolutePath:(place_id,content_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/contents/#{content_id}/info/path", (response)->
				if response.err?
					done.reject response.err
				else
					done.resolve(response.path)
			.fail ->
				done.reject "Request error"
			return done.promise()
	}
