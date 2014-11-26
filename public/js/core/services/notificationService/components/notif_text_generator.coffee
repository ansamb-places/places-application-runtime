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
		'place:new':
			template:'The place <span class="emphase"><%- data.name %></span> has been created by <b><%- data.firstname %> <%- data.lastname %></b>'
			action:'#place/<%= ref %>'
		'place:request':
			template:'<span class="uid"><%- data.firstname %> <%- data.lastname %></span> wants you to belong to the place <span class="emphase"><%- data.name %></span>'
			action:null
		'place:rename':
			template:'The place <span class="emphase"><%- data.old_name %></span> has been renamed to <span class="emphase"><%- data.new_name %></span>'
			action:null
		'place:disable':
			template:'The place <span class="emphase"><%- data.place_name %></span> has been disabled'
			action:null
		'ansamber:accepted':
			template:'<span class="uid"><%- data.firstname %> <%- data.lastname %></span> is now in the place <span class="emphase"><%- data.place_name %></span>'
			action:null
		'contact':
			template:(notification)->
				text = ""
				status = notification.data.status
				if status=="pending"
					text = "request you to be his friend"
				else if status=="deleted"
					text = "has been deleted"
				else
					text = "has accepted your add request"
				return "<span class='uid'>#{notification.data.firstname} #{notification.data.lastname}</span> #{text}"
			action:null
		'update:available':
			template:'Places update available'
			action:'#update/ask/<%- data.timestamp %>'
		'update:done':
			template:'Places updated'
			action:null
	}