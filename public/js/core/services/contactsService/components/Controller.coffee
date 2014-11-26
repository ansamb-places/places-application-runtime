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
	'cs!app'
	'cs!./ViewFactory'
	'cs!backend_api/ContactBackendAPI'
	'cs!backend_api/ContentBackendAPI'
	'cs!./DataManager'
],(App,ViewFactory,ContactAPI, ContentBackendAPI, DataManager)->
	collection = DataManager.getContactCollection()
	controller =
		_add_contact_request:(contact_object)->
			aliases = _.values(contact_object.aliases)
			if _.isArray(aliases) and aliases.length > 0
				alias_obj = aliases[0]
			else
				alias_obj = null
			return ContactAPI.addContact(alias_obj)
		add_contact:->
			currentFrag = Backbone.history.fragment
			if currentFrag =="" or currentFrag == "contact/add"
				currentFrag = "place/"
			view = ViewFactory.buildAddContactView()
			view.on
				'contact:add':(contact_object)=>
					@_add_contact_request(contact_object).done ->
						Backbone.history.navigate(currentFrag,{replace:true,trigger:true})
					.fail (err)->
						view.showError err
				'render':->
					Backbone.history.navigate("contact/add",{trigger:false})
				"back":()->
					Backbone.history.navigate(currentFrag,{replace:true,trigger:true})
			App.activityFeed.show view
			App.vent.trigger "placeToolbar:change",'add_contact', {item_id:'menu/addContactMenu'}
		import_contacts:->
			view = ViewFactory.buildImportContactsView()
			view.on
				'search:contacts':(emails)->
					contactsView= ViewFactory.buildImportContactsResult(emails)
					App.vent.trigger 'placeToolbar:changeActions',
						[
							{
								title:"invite",
								ui_icon:'<span class="p-button-round-rec p-background-contact p-button-padding" style=\'margin-top:10px;\'>invite</span>',
								cb:()->
									models = contactsView.getSelectedItems()
									_.each models,(model)->
										model.set 'invited',true
							}
						]
					contactsView.listenTo contactsView, 'multiselect:enable', ()->
						App.vent.trigger 'placeToolbar:showActions'
					contactsView.listenTo contactsView, 'multiselect:disable', ()->
						App.vent.trigger 'placeToolbar:hideActions'
					contactsView.listenTo contactsView,'itemview:contact:add',(iv,contact_object)->
						ContactAPI.addContact(contact_object.toJSON())
					contactsView.on 'action:leave',()->
						Backbone.history.navigate("#place/",{trigger:true})
					App.activityFeed.show contactsView 
				'action:leave':()->
					Backbone.history.navigate("#place/",{trigger:true})
			App.activityFeed.show view
			
			App.vent.trigger "placeToolbar:change",'settings', {
				item_id:'item/importContacts',
				title:"<span class='p-color-contact'> new contact </span>",
				menu:[
					{type:'href',
					name : "<span class='p-border-color-contact active'> import contacts</span>",
					href : "",
					item_id:'contact/import'}]}
		showManageContacts:->
			view = ViewFactory.buildManageContactsView()
			view.on
				'itemview:contact:confirm_delete':(childView,uid)=>
					@confirm_delete_contact uid
					view.confirm_delete()
				'itemview:contact:cancel_delete':(childView,uid)=>
					@cancel_delete_contact uid
					view.cancel_delete()
				'itemview:contact:accept':(childView,uid)=>
					@accept_request uid
				'contact:delete':(uid)=>
					@delete_contact uid
					view.cancel_delete()
				'contact:leave':()=>
					Backbone.history.navigate('place/',{replace:true,trigger:true})
			App.activityFeed.show view
			App.vent.trigger "placeToolbar:change",'settings',{item_id:'item/contacts',title:'contacts'}
		manage_contacts:->
			console.log "manage contacts"
		accept_request:(uid)->
			ContactAPI.acceptContact(uid)
			.fail (err)->
				alert err
		confirm_delete_contact:(uid)->
			collection.each (model)->
				if model.get('uid') == uid then model.set('selection',true) else model.set('selection',false)
		cancel_delete_contact:(uid)->
			collection.findWhere({uid:uid})?.set('selection', false)
		delete_contact:(uid)->
			contact = collection.findWhere({uid:uid})
			alert 'Contact not found' if contact == null or _.isUndefined(contact)
			ContactAPI.removeContact(uid).done (data)->
				collection.remove(contact)
			.fail (err)->
				alert err
		tag_later:(uid)->
			ContactAPI.laterContact(uid)
			.fail (err)->
				alert err
		send_file_to_contact:(content_id, source_place_id, contact_id)->
			conversationsController = App.module('ConversationsService').api.getController()
			conversationsController.send_file_to_contact(content_id, source_place_id, contact_id)
	return controller
