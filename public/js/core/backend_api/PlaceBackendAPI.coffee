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
		createRandomPlace:->
			done = $.Deferred()
			$.get "/core/api/v1/places/random_place/",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.data)
			.fail ->
				done.reject "Request error"
			return done.promise()
		addAnsamberToPlace:(uid,place_id)->
			done = $.Deferred()
			$.ajax 
				type : "PUT"
				url : "/core/api/v1/places/#{place_id}/ansambers/#{uid}"
			.done (reply)=>
				if reply.err!=null
					console.log reply.err
					done.reject "Error on ansamber add"
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		removeAnsamberFromPlace:(uid,place_id)->
			done = $.Deferred()
			$.ajax
				url : "/core/api/v1/places/#{place_id}/ansambers/#{uid}"
				type : "DELETE",
			.done (reply) =>
				if reply.err!=null
					console.log reply.err
					done.reject "Error on ansamber delete"
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		getAnsambersForPlace:(place_id)->
			done = $.Deferred()
			$.get "/core/api/v1/places/#{place_id}/ansambers/",(reply)=>
				if reply.err!=null
					console.log reply.err
					done.reject "Error on ansamber get"
				else
					done.resolve(reply.ansambers)
			.fail ->
				done.reject "Request error"
			return done.promise()
		getUniqueConversationPlace:(uid)->
			done = $.Deferred()
			$.get "/core/api/v1/places/unique/#{uid}/conversation",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.place)
			.fail ->
				done.reject "Request error"
			return done.promise()
		getAllConversations:()->
			done = $.Deferred()
			$.get "/core/api/v1/places/?type=conversation",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.data)
			.fail ->
				done.reject "Request error"
			return done.promise()
		changePlaceStatus:(place_id,status)->
			done = $.Deferred()
			$.post "/core/api/v1/places/#{place_id}/status/#{status}",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.data)
			.fail ->
				done.reject "Request error"
			return done.promise()
		deletePlace:(place_id)->
			done = $.Deferred()
			$.ajax
				type: "DELETE",
				url: "/core/api/v1/places/#{place_id}"
			.done (reply)->
					if reply.err?
						done.reject(reply.err)
					else
						done.resolve(reply.data)
			.fail ->
					done.reject "Request error"
			return done.promise()
		renamePlace:(place_id,new_name)->
			done = $.Deferred()
			$.ajax
				type : "PUT"
				url : "/core/api/v1/places/#{place_id}"
				data : {name:new_name}
			.done (reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
	}