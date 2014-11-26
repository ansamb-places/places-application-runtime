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
	'cs!./components/DataManager',
	'cs!./components/ViewFactory',
	'cs!./components/Router',
	'cs!./components/Controller',
	'cs!modules/EventsManager',
	'cs!modules/FileManager',
	'cs!modules/interactions/dragAndDropSupport',
	'cs!backend_api/SyncBackendAPI'
],(App,DataManager,ViewFactory,Router,Controller,EventsManager,FileManager,DragAndDrop,SyncAPI)->
	ServiceModule = App.module('PlacesService')
	ServiceModule.startWithParent = true
	ServiceModule.contents = null
	ServiceModule.addInitializer ()->
		@ready = $.Deferred()
		menuLayoutObject = ViewFactory.buildPlacesMenuView (itemView)->
			#this function is called when a place has been created
			pid = itemView.model.get('id')
			dd = new DragAndDrop {dom:itemView.$el,delegateEvent:itemView}
			dd.on "drag&drop",(data)->
				if !DataManager.getPlace(pid).isReadOnly()
					if DataManager.ContentsCollectionCache?.place_id == pid
						FileManager.fileUploadManagement(data.files,pid,DataManager.ContentsCollectionCache)
					else 
						FileManager.fileUploadManagement(data.files,pid)
				else
					Controller.showReadOnlyMessage()
		menuLayout = menuLayoutObject.layout
		App.placesMenu.show menuLayout
		if DataManager.isPlaceCollectionEmpty()
			App.activityFeed.show ViewFactory.buildEmptyView()
		###Events on Views###
		menuLayout.on 
			'place:create':(place_name) ->
				Controller.createPlace(place_name)
		menuLayout.placesRequests.currentView.on
			'place:accept':(place_id)->
				Controller.changeRequestStatus(place_id,"validated")
				Controller.showFullScreen 'list', place_id
			'place:reject':(place_id)->
				Controller.changeRequestStatus(place_id,"later")
			'place:later':(place_id)->
				Controller.changeRequestStatus(place_id,"later")
		menuLayout.places_list.currentView.on 
			'itemview:place:options':(view,place_id)->
				Controller.paramsPlace(place_id)
			'itemview:place:click':(view,place_id)->
				# Controller.selectPlace(place_id)
				Controller.showFullScreen('list',place_id)
			'itemview:place:delete':(view,place_id)->
				Controller.deletePlace(place_id)
			'itemview:place:new_file':(view, place_id, file_id, origin_place_id)->
				if !DataManager.getPlace(place_id)?.isReadOnly()
					FileManager.copyFileToPlace(place_id, file_id, origin_place_id)
				else
					Controller.showReadOnlyMessage()
			'itemview:place:addAnsamberToPlace':(view, user_id, user_name, place_id, place_name, owner)->
				Controller.addAnsamberToPlace user_id, user_name, place_id, place_name, owner
		EventsManager.on 'file.watcher:copying', (place_id) ->
			menuLayout.notifyView 'file.watcher:copying', place_id
		###Catch events from App###
		App.reqres.setHandler 'contact:in_place',()->
			return Controller.getAnsambers()
		App.vent.on 'place:current',(placeName)->
			if placeName?
				App.vent.trigger 'place:change',Controller.getAnsambers()
			else App.vent.trigger 'place:change',null
		#here the promise is not useful but it can be in certain case
		@ready.resolve()
	ServiceModule.api=
		getViewFactory:()->
			return ViewFactory
		getDataManager:()->
			return DataManager
		getController:()->
			return Controller
	return ServiceModule

	
