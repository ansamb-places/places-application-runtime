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
	'cs!app',
	'cs!./components/DataManager'
	'cs!./components/ViewFactory'
	'cs!./components/Router'
	'cs!./components/Controller'
	'cs!modules/FileManager'
	'cs!modules/interactions/dragAndDropSupport'
	'cs!./components/EventManager'
	]
,(App,DataManager,ViewFactory,Router,Controller,FileManager,DragAndDrop,EventManager)->
	ServiceModule = App.module('ContactsService')
	ServiceModule.startWithParent = true
	ServiceModule.addInitializer ->
		@ready = $.Deferred()
		#here the promise is not useful but it can be in certain case
		menuLayoutObject = ViewFactory.buildRightContactBarView (itemView)->
			dd = new DragAndDrop {dom:itemView.$el,delegateEvent:itemView}
			dd.on "drag&drop",(data)->
				App.vent.trigger 'contact:file:drag_and_drop',itemView.model.toJSON(),data
		menuLayout = menuLayoutObject.layout
		App.placesContacts.show menuLayout
		view= menuLayout.contactsList.currentView
		menuLayout.on
			'action:add':->
				Controller.add_contact()
		menuLayout.contactsList.currentView.on 
			'action:add':->
				Controller.add_contact()
			'action:manage':->
				Controller.manage_contacts()
			'action:requests':->
				Controller.show_pending_contacts()
			'itemview:contact:click':(childView,ansamber)->
				#notify other apps that a contact have been clicked
				App.vent.trigger 'contact:click',ansamber
			'itemview:contact:visio':(childView,uid)->
				#notify other apps of conference request
				App.vent.trigger 'contact:visio',uid
			'itemview:contact:accept':(childView,uid)->
				Controller.accept_request uid
			'itemview:contact:delete':(childView,uid)->
				Controller.delete_contact uid
			'contact:in_place':->
				ansambers= App.request 'contact:in_place'
				ansambers.done (ansambers)->
					menuLayout.contactsList.currentView.collection.filterBy('uid',(model)->
						return ansambers.indexOf(model.get('uid'))+1
						)
			"itemview:contact:sendFileFromPlace":(childView, content_id, source_place_id, ansamber)->
				Controller.send_file_to_contact(content_id, source_place_id, ansamber)

		menuLayout.contactsRequests.currentView.on
			'contact:accept':(uid)->
				Controller.accept_request uid
			'contact:later':(uid)->
				Controller.tag_later uid
			'contact:reject':(uid)->
				Controller.delete_contact uid
		App.vent.on "place:change",(ansambers)->
			###if view.ui.in_place.hasClass('selected')
				if not ansambers?
					view.filter_all(null)
					view.disable_ui("in_place")
				else
					view.collection.resetFilters()
					ansambers.done (ansambers)->
						view.collection.filterBy('uid',(model)->
							return ansambers.indexOf(model.get('uid'))+1
							)
			else 
				if not ansambers?
					view.disable_ui("in_place")
				else view.enable_ui("in_place")###
		#handle global requests
		App.reqres.setHandler "ansamber:view:choice",->
			return ViewFactory.buildSelectContactView()
		App.reqres.setHandler "ansamber:uid:resolve",(uids,cb)->
			cb DataManager.getAnsamberFromUid(uids)
		@ready.resolve()
	ServiceModule.api=
		getViewFactory:()->
			return ViewFactory
		getDataManager:()->
			return DataManager
		getController:()->
			return Controller
	return ServiceModule
