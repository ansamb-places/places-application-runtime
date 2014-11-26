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
	'text!../templates/AddContact.tmpl',
	'cs!backend_api/ContactBackendAPI',
	'text!../templates/contactSuggest.tmpl'
],(tmpl,ContactBackendAPI,suggest_tmpl)->
	class View extends Backbone.Marionette.ItemView
		className: 'p-add-contact'
		initialize:(options)->
			_.extend @,Backbone.Events
			super(options)
		template: _.template(tmpl)
		events:
			'keyup input':'keyup'
			'click .add_btn':'addContact'
			'click .close':'back'
		ui:
    		input: ".p-search-input"
    		contact_search_result: ".contacts-result"
    		contact_search_progress: ".contact-checkExists .progress"

		showError:(error)->
			@$el.append $("<div class='error'>#{error}</div>")
		back:()->
			@trigger 'back'
		close:->
			clearTimeout(@keyUpTimeout) if @keyUpTimeout?
			@trigger 'close'
			@unbind()
			@remove()

		showContacts:(results)->
			@ui.contact_search_result.empty()
			if results.length == 0
				@ui.contact_search_result.html "No contact found with this email"
			_.each results,(contact)=>
				$item = $(_.template(suggest_tmpl,contact))
				@ui.contact_search_result.append $item
				$("[data-action='add']",$item).click (e)=>
					$(e.currentTarget).replaceWith("<span class='pending-satus'>pending</span>")
					@trigger 'contact:add',contact
			@ui.contact_search_result.show()
		keyup:(e)->
			clearTimeout(@keyUpTimeout) if @keyUpTimeout?
			contact_search_progress = @ui.contact_search_progress
			contact_search_result = @ui.contact_search_result
			add_button = @$el.find('.add_btn')
			@keyUpTimeout = setTimeout =>
				email = $(e.currentTarget).val()
				if email==""
					contact_search_progress.hide()
					contact_search_result.hide()
					add_button.hide()
					return
				contact_search_progress.show()
				ContactBackendAPI.searchContact(email).done (contact)=>
					if contact then contact = [contact] else contact = []
					contact_search_progress.hide()
					@showContacts contact
				.fail (err)=>
					$(e.currentTarget).focusout()
					@ui.contact_search_result.html err
					contact_search_progress.hide()
			,800
		
	return View