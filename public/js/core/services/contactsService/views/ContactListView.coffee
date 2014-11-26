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
	'cs!./RightContactBarItemView'
	'cs!../views/ContactBarEmptyView'
],(ItemView,EmptyView)->
	return class RightContactBarView extends Backbone.Marionette.CollectionView
		tagName:'ul'
		# id : 'contactsList'
		className : 'p-contact-list'
			
		itemView:ItemView
		emptyView: EmptyView
		###ui:
			all_contacts:'.all_contacts'
			in_place:'.in_place'###
		events:
			"click .all_contacts":"filter_all"
			"click .in_place":"filter_in_place"
		disable_ui:(el)->
			@ui[el].addClass('disable')
		enable_ui:(el)->
			@ui[el].removeClass('disable')
		menu_click:(e)->
			e.preventDefault() if e?
			action = $(e.currentTarget).data('action')
			console.log action
			@trigger "action:#{action}"
			@close_menu()
		filter_all:(e)->
			e.preventDefault() if e?
			if not @ui.all_contacts.hasClass('selected')
				@ui.in_place.removeClass('selected')
				@ui.all_contacts.addClass('selected')
				@collection.resetFilters()
		filter_in_place:(e)->
			if e?
				e.preventDefault()
			if not @ui.in_place.hasClass('selected')
				if not @ui.in_place.hasClass('disable')
					@ui.in_place.addClass('selected')
					@ui.all_contacts.removeClass('selected')
					@trigger "contact:in_place"
		close_menu:->
			menu = $("#contacts-options",@$el)
			menu.foundation('dropdown', 'close',menu)
