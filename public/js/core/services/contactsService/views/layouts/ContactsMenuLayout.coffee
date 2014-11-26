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
define ['text!./contactsMenuLayout.tmpl'],(tmpl)->
	return Backbone.Marionette.Layout.extend {
		tagName: 'div'
		className: 'p-contacts-menu-layout'
		template:->
			return tmpl
		regions: 
			contactsList:"#contactsList"
			contactsRequests:"#contactsRequests"
		events:
			"click #ansamb_menu_add_contact":"add_contact"
		initialize:(options)->
			@contactsRequests.on "show",(view)=>
				view.listenTo view,"request:hide",()=>
					@$el.removeClass('p-request-enabled')
				view.listenTo view,"request:show",()=>
					@$el.addClass('p-request-enabled')
				@$el.addClass('p-request-enabled') if view.displayed
		add_contact:(e)->
			e.preventDefault()
			@trigger 'action:add'
	}