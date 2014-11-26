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
		addContact:(alias_obj)->
			done = $.Deferred()
			$.post "/core/api/v1/contacts/",alias_obj,(response)->
				if response.err==null or typeof response.err == 'undefined'
					done.resolve()
				else
					done.reject response.err
			.fail ->
				done.reject "Request error"
			return done.promise()
		acceptContact:(uid)->
			done = $.Deferred()
			$.post "/core/api/v1/contacts/accept", {uid:uid}, (response)->
				done.resolve(response)
			.fail ->
				done.reject "Request error"
			return done.promise()
		removeContact:(uid)->
			done = $.Deferred()
			$.ajax
				url : "/core/api/v1/contacts/#{uid}"
				type : "DELETE"
				success : (response)->
					if response.err==null or _.isUndefined(response.err)
						done.resolve()
					if _.isArray(response.err) and response.err[0]?.errno == 19
						done.reject "This user belongs to existing places, you can't delete it"
					else
						done.reject "An error has occured"
				fail : ->
			 		done.reject "Request error"
			return done.promise()
		laterContact:(uid)->
			done = $.Deferred()
			$.post "/core/api/v1/contacts/later", {uid:uid}, (response)->
				done.resolve(response)
			.fail ->
				done.reject "Request error"
			return done.promise()
		searchContact:(email)->
			done = $.Deferred()
			body =
				type:'email'
				alias:email
			$.post "/core/api/v1/contacts/aliases/lookup",body,(response)->
				if response.err?
					done.reject response.err
				else
					done.resolve response.contact
			.fail ->
				done.reject "Request error"
			return done.promise()
		syncStatus:->
			done = $.Deferred()
			$.get "/core/api/v1/contacts/sync_status/",(response)->
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
	}