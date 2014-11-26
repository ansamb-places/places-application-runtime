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
define [
	'cs!backend_api/ContactBackendAPI'
	'cs!backend_api/PlaceBackendAPI'
	],(ContactBackendAPI,PlaceBackendAPI)->
	return {
		NGContact_id:null
		getNGInfo:()->
			done = $.Deferred()
			$.get "/core/api/v1/contacts/get_ng_contact/",(response)=>
				if response.err
					done.reject response.err
				else
					@NGContact_id=response.contact.uid
					done.resolve response.contact
			.fail ->
				done.reject "Request error"
			return done.promise()
		acceptNGContact:()->
			return ContactBackendAPI.acceptContact(@NGContact_id)
		acceptNGPlace:(place_id)->
			return PlaceBackendAPI.changePlaceStatus(place_id,"validated")
		addNG:()->
			done = $.Deferred()
			$.get "/core/api/v1/contacts/add_ng/",(response)=>
				done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
	}	