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
define ['text!./placesMenuLayout.tmpl'],(tmpl)->
	return Backbone.Marionette.Layout.extend {
		tagName: 'div'
		className: 'p-places-menu-layout'
		template:->
			return tmpl
		regions:
			places_list: "#places-list"
			otherplaces: "#otherplaces"
			placesRequests:"#placesRequests"
		events:
			"click #ansamb_menu_create_place": "create_place"
		initialize:(options)->
			@placesRequests.on "show",(view)=>
				view.listenTo view,"request:hide",()=>
					@$el.removeClass('p-request-enabled')
				view.listenTo view,"request:show",()=>
					@$el.addClass('p-request-enabled')
				@$el.addClass('p-request-enabled') if view.displayed
		create_place: (e)->
			e.preventDefault()
			if @creating == undefined || @creating == false
				@creating = true
				@el = $(e.currentTarget)
				@htmlbackup = @el.html()
				@el.addClass("n-active")
				@el.html('<input class="p-newplace-input"> </input> <span id="add-place" class="fi-arrow-right"> </span>')
				@el.find('.p-newplace-input').focus()

				@el.find("#add-place").click (e)=>
					@trigger_place_creation()

				@el.find('.p-newplace-input').on 
					keyup: (e)=>
						if e.keyCode ==13 
							@trigger_place_creation()
						else if e.keyCode == 27
							@close()
					focusout: =>
						setTimeout ()=>
							@close()
						, 100


		close:()->
			@el.html(@htmlbackup)
			@el.removeClass("n-active")
			@creating = false

		trigger_place_creation:()->
			new_place_name = @el.find(".p-newplace-input").val()
			if new_place_name.length > 0
				@trigger 'place:create', new_place_name
				@close();
	}
