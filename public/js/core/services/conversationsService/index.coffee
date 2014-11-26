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
	'cs!./components/ViewFactory'
	'cs!./components/Router'
	'cs!./components/Controller'
	'cs!./entities/Conversations'
	'cs!./components/EventManager'
	'cs!backend_api/SyncBackendAPI'
	'cs!backend_api/PlaceBackendAPI'
	'cs!modules/FileManager'
	]
,(App,ViewFactory,Router,Controller,Conversations,EventManager,SyncBackendAPI,PlaceBackendAPI,FileManager)->
	ServiceModule = App.module('ConversationsService')
	ServiceModule.startWithParent = true
	ServiceModule.addInitializer ->
		#here the promise is not useful but it can be in certain case
		@ready = $.Deferred()
		App.vent.on 'contact:click',(ansamber)->
			Controller.show_conversation_with ansamber,'chatbox',true
		App.vent.on 'contact:file:drag_and_drop',(ansamber,data)->
			Controller.show_conversation_with(ansamber,"chatbox").done (place_id,view)->
				view.collection.onAfterFetch ()->
					FileManager.fileUploadManagement(data.files,place_id,view.collection,{randomize:true})

		@ready.resolve()
		v = ViewFactory.buildConversationsNotificationView({el:"#messages"})
		v.on
			'itemview:action:show_history':(childItemView,place_id)->
				Controller.show_conversation_by_id place_id,'chatbox',{focus:true}
			'itemview:ansamber:get':(childItemView,place_id,cb)->
				PlaceBackendAPI.getAnsambersForPlace(place_id).done (ansambers)->
					cb ansambers
				.fail (err)->
					console.log "error on ansamber get"
					cb []
			'itemview:contact:get':(childItemView,ansambers,cb)->
				uids= _.map ansambers,(item)-> 
					return item.uid
				App.reqres.request "ansamber:uid:resolve", uids,cb
		v.render()
	ServiceModule.api=
		getViewFactory:()->
			return ViewFactory
		getController:()->
			return Controller
		getDataManager:()->
			return DataManager
	return ServiceModule
