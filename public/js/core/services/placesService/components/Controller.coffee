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
	'cs!services/placesService/components/DataManager'
	'cs!services/placesService/components/ViewFactory'
	'cs!modules/ViewLoader'
	'cs!modules/ApplicationManager'
	'cs!modules/RequireManager'
	'cs!modules/dialogMessagesManager'
	'cs!services/placesService/components/EventManager'
	'cs!backend_api/ApplicationBackendAPI'
	'cs!backend_api/SyncBackendAPI'
	'cs!backend_api/PlaceBackendAPI'
	'cs!backend_api/ContentBackendAPI'
	'cs!backend_api/NGBackendAPI'
	'cs!modules/interactions/dragAndDropSupport'
	'cs!entities/Contents'
	'cs!modules/FileManager'
	'cs!modules/interactions/JqueryUIDragAndDropManager'
	'cs!modules/localSettingsManager'
]
,(App,DataManager,ViewFactory,ViewLoader,ApplicationManager,RequireManager,
dialogMessagesManager,EventManager,AppAPI,SyncAPI,PlaceAPI,ContentAPI,NGBackendAPI,
DragAndDrop,ContentEntities,FileManager,JqueryUIDragAndDropManager,settingsManager)->
	#private functions
	currentPlace= null
	title_change=(old_name, new_name, place_id, dismiss)->
		model = DataManager.getPlace(place_id)
		model.set('name',new_name)
		PlaceAPI.renamePlace(place_id,new_name).fail (err)->
			alert err
			dismiss()
			model.set('name',old_name)

	toolBarTitleUpdate = (model)->
		m = model.toJSON()
		App.vent.trigger 'placeToolbar:update:title',_.escape(m.name)

	###
	%%%%%%%%%%%% PLACE CONTEXT INIT FUNCTION %%%%%%%%%%%%%%%%%%%%%
	###
	placeContext = {place_id:null,context:null}
	_initPlaceContext =(place_id,item_id)->
		#retrieve the place model
		place = DataManager.getPlace(place_id)
		if not place?
			Backbone.history.navigate("place/",{trigger:true})
			return null
		if placeContext?.place_id != place_id
			#remove old callback on place model change
			placeContext.context.place.off "change",toolBarTitleUpdate if placeContext?.context?.place
			previous_place = currentPlace
			currentPlace = place_id
			contentsCollection = DataManager.getContentCollection(place_id)
			### SYNC MANAGEMENT ###
			#disable sync for the previous place (for now)
			#TODO create a sync manager to keep sync activated on most and last used places
			#if previous_place?
				#SyncAPI.disableSyncForPlace(previous_place).done ->
				#	console.log "real time sync disable for place #{previous_place}"
				#.fail (error)->
				#	alert error

			#activate sync for this place
			#SyncAPI.enableSyncForPlace(place_id).done ->
			#	console.log "real time sync enable for place #{place_id}"
			#.fail (error)->
			#	console.log "error while turning on sync for place #{place_id}"

			ansambersToolbarView= ViewFactory.buildPlaceAnsambersDDView place_id,place.get('owner_uid')
			ansambersToolbarView.on
				"itemview:ansamber:delete":(childView,uid)->
					PlaceAPI.removeAnsamberFromPlace(uid,place_id).done ()->
						childView.model.destroy()
			EventManager.setTrackAnsamber(ansambersToolbarView.collection,place_id)
			App.vent.trigger "place:current",place_id
			EventManager.setTrackedContent(contentsCollection,place_id)
			place.on "change",toolBarTitleUpdate
			placeContext = {
				place_id:place_id
				context:{
					place: place,
					contentsCollection:contentsCollection
					ansambersToolbarView:ansambersToolbarView
				}
			}

		actions = {}
		if place.get('owner_uid')==null
			actions.title_change = title_change
			delete_place_message= "delete the place"
		else 
			delete_place_message= "leave the place"
		sync_state_to_msg = (sync_state)->
			if sync_state
				return "stop sync"
			else return "restart sync"
		if place.get('status')?.indexOf("readonly") == -1
			menu= [
				{
					text:delete_place_message
					cb:->
						api.deletePlace(place_id).done ->
							Backbone.history.navigate "place/",{trigger:true}
							placeContext = {place_id:null,context:null}
				}
			]
		else
			menu = []
		if not place.isDisabled()
			modifyToolbar = (sync_enabled,date,modifier)->
				place.set('auto_sync',sync_enabled)
				place.set('last_sync_date',date,{silent:true})
				modifier.setText(sync_state_to_msg(sync_enabled))
				modifier.setSyncDate(date)
			menu.push({
				text:sync_state_to_msg(place.get('auto_sync'))
				cb:(modifier)->
					if place.get('auto_sync')
						SyncAPI.disableAutoSyncForPlace(place_id).done (date)->
							modifyToolbar false,date,modifier
					else
						SyncAPI.enableAutoSyncForPlace(place_id).done (date)->
							modifyToolbar true,date,modifier
				init:(modifier)->
					updateItem = ->
						if place.isSyncable()
							modifier.showItem()
						else
							modifier.hideItem()
					place.listenTo place,'change:status change:network_synced',updateItem
					updateItem()
				},
				{
					text:'resync all'
					cb:(modifier)->
						SyncAPI.enableSyncForPlace(place_id,{reset:true})
					init:(modifier)->
						updateItem = ->
							unless place.isDisabled()
								modifier.showItem()
							else
								modifier.hideItem()
						place.listenTo place,'change:status change:auto_sync',updateItem
						updateItem()
				}
			)
		App.vent.trigger "placeToolbar:change",'place',
		{
			item_id:item_id
			place_id:place_id,
			placeName:place.get('name')
			owner: place.get('owner') ? null
			date:place.get('creation_date')
			sync_date:place.get("last_sync_date")
			cb:
				'item/add_files':()=>
					if place.get('status') == 'validated'
						addFilesToPlace(place_id,placeContext.context.contentsCollection)
					else
						@
						api.showReadOnlyMessage()
			views:{'item/contacts':placeContext.context.ansambersToolbarView}
			context_menu:menu
		},actions

		return placeContext.context
	
	dragAndDropManage = (view, DOMparent, place_model)->
		el = $('#p-main-column')
		el.droppable
			scope:'places-draggable'
			hoverClass:"drop-hover"
			tolerance:"intersect"
			over:(event,ui)=>
				if ui.helper.data('type') == 'ansamber'
					el.addClass("p-dropOverlay p-contact-overlay")
					ui.helper.showAddIcon(true)
			drop:(event,ui) =>
				if place_model==null
					el.removeClass("p-dropOverlay")
					return api.showReadOnlyMessage()
				type = ui.helper.data('type')
				if type is 'ansamber'
					api.addAnsamberToPlace ui.helper.data('uid'), ui.helper.data('fullName') , place_model.get('id'), place_model.get('name'), place_model.get('owner_uid')
					el.removeClass("p-dropOverlay")
			out:(event,ui)=>
				if ui.helper.data('type') == 'ansamber'
					el.removeClass("p-dropOverlay p-contact-overlay")
					ui.helper.showAddIcon(false)
		JqueryUIDragAndDropManager.registerNewDroppable(el, 50)

	addFilesToPlace=(place_id,collection)->
		return api.showReadOnlyMessage() if DataManager.getPlace(place_id)?.get('status')=="readonly"
		if $('#addFileTag').length ==0
			fileInput= $('<input id="#addFileTag" type="file" name="addFileTag" style="display: none;" multiple/>')
			$("body").append fileInput
		else
			fileInput = $('#addFileTag')[0]
		fileInput.trigger('click')
		fileInput.change (e)->
			files_array= _.map e.target.files,(item)=>
				return _.pick item,'name','path','size','type','lastModifiedDate'
			FileManager.fileUploadManagement(files_array,place_id,collection)

	###
	%%%%%%%%%%%%%%%%%%%% PUBLIC API %%%%%%%%%%%%%%%%%%%%%%%
	###
	api = {
		switchPlace:false
		home:->
			App.vent.trigger "placeToolbar:change","default",{title:"<span class='p-home-title'>home</span>"}
			#App.activityFeed.show ViewFactory.buildHomeView()
			View= ViewFactory.buildNGHomeView()
			ContactCollection= App.module('ContactsService').api.getDataManager().getContactCollection()
			PlaceCollection= DataManager.getPlaceCollection()
			ng_info=null
			View.showLoading(true)
			NGBackendAPI.getNGInfo().done (contact)->
				View.contact_model=ContactCollection.findWhere({uid:contact.uid})
				View.place_model=PlaceCollection.findWhere({owner_uid:contact.uid})
				PlaceCollection.on 'add',(model)->
					if model.get("owner_uid")==contact.uid
						View.place_model= model
						model.listenTo model,'change:network_synced',->
							value = mode.get('network_synced')
							if value == 2 or value == "2"
								settingsManager.setSetting('ng_invite',"done")
						View.showLoading(false)
				ContactCollection.on 'add',(model)->
					if model.get("uid")==contact.uid
						View.contact_model= model
						View.showLoading(false)
				View.showLoading(false)
			.fail ()->
				setTimeout ()->
					View.showLoading(false)
				,1000
			View.on 
				"send:request":()->
					NGBackendAPI.addNG()
					View.showLoading(true)
				"contact:accept":()->
					View.showLoading(true)
					NGBackendAPI.acceptNGContact().done (data)->
						console.log "accept"
					.fail (err)->
						View.showLoading(false)

				"place:accept":()->
					View.showLoading(true)
					NGBackendAPI.acceptNGPlace(View.place_model.id).done (data)->
						View.showLoading(false)
						Backbone.history.navigate "#place/type/list/"+View.place_model.id,{trigger: true}
					.fail (err)->
						View.showLoading(false)
			App.activityFeed.show View
		createPlace:(name)->
			$.post "/core/api/v1/places/",{name:name,type:"share"},(response)=>
				if response?.err
					alert response.err.message
				else
					DataManager.addPlace(response.data)
					Backbone.history.navigate "#place/type/list/"+response.data.id,{trigger: true}

		selectPlace:(place_id)->
			place_info= _initPlaceContext(place_id,"item/fullScreen")
			@switchPlace= true
			View = ViewFactory.buildActivityFeedView(place_id)
			View.setPlaceName(place_id)
			ApplicationManager.get().then (instance)=>
				View.on
					'request:view':(type,cb)->
						name = instance.getApplicationForType(type)
						if name==null
							cb DefaultItemView
						else	
							ViewLoader.getView name,'wall',(View)->
								cb View
					dd = new DragAndDrop {dom:View.$el,delegateEvent:View}
					dd.on "drag&drop",(data)=>
						FileManager.fileUploadManagement(data.files,place_id,View.collection)
					'content:new':(application_name,data)->
						AppAPI.newContent(application_name,place_id,data).done (content_model)->
							View.collection.add(content_model)
						.fail (error)->
							alert error
					'view:close':()=>
						if not @switchPlace
							App.vent.trigger "place:current",null
							@currentPlace= null
					'view:render':()=>
						@switchPlace= false

				Backbone.history.navigate "#place/"+place_id
				App.activityFeed.show View

		showFullScreen:(viewType,place_id)->
			type = 'file'
			resetCollection = place_id == currentPlace
			place_info = _initPlaceContext(place_id,"item/#{viewType}")
			if place_info is null then return
			ApplicationManager.get().then (instance)=>
				name = instance.getApplicationForType(type)
				if name==null
					alert "Format not supported"
				else
					place = place_info.place
					place.set 'selected', true
					unless place.isReady()
						App.vent.trigger 'placeToolbar:disable', true
						place.once 'change:network_synced', ()->
							if place.isReady()
								App.vent.trigger 'placeToolbar:disable', false
					App.activityFeed.show ViewFactory.buildLoadingView()
					if resetCollection
						place_info.contentsCollection.each (model)->
							model.set("_multiselect_selected",false)
					ViewFactory.buildFullScreenView(place,viewType,name,type).done (View)=>
						###status:all Iterractions####
						View.listenTo View, 'multiselect:enable', ()->
							App.vent.trigger 'placeToolbar:showActions'
						View.listenTo View, 'multiselect:disable', ()->
							App.vent.trigger 'placeToolbar:hideActions'
						View.listenTo View, 'contextmenu:download',(models)->
							FileManager.downloadFiles place_id,View.getSelectedItems()
						View.on
							"itemview:content:download":(itemView,model)=>
								@markContentAsRead(place_info.place,model)
								FileManager.downloadFiles(place_id,[model])
							"itemview:content:open_folder":(itemview,model)=>
								@markContentAsRead(place_info.place,model)
								FileManager.openFileInFinder place_id,model.get('id')
							"itemview:content:preview":(itemview,model)=>
								@markContentAsRead(place_info.place,model)
						###status:validated Interactions####
						if place.get('status')=='validated' or !place.isReadOnly()
							App.vent.trigger 'placeToolbar:changeActions',
								[
									{
										title:"deleteAll",
										ui_icon:'<div class="deleteAll"></div>',
										cb:()->
											models = View.getSelectedItems()
											FileManager.deleteFiles(place_id,View.collection,models)
									},
									{
										title:"downloadAll",
										ui_icon:'<div class="downloadAll"></div>',
										cb:()->
											models = View.getSelectedItems()
											FileManager.downloadFiles(place_id,models)
									}
								]
							if View.dragAndDrop
								dd = new DragAndDrop {dom:$("#p-main-column"),delegateEvent:View}
								dd.on "drag&drop",(data)=>
									FileManager.fileUploadManagement(data.files,place.get('id'),View.collection.superset())
								View.on "close",->
									dd.remove() #remove old drag&drop listeners
							dragAndDropManage(View, View.$el, place)

							View.listenTo View, 'contextmenu:delete',(models)->
								FileManager.deleteFiles place_id,View.collection,View.getSelectedItems()
							View.on
								"itemview:content:rename":(itemView,model,new_name)=>
									@markContentAsRead(place_info.place,model)
									ContentAPI.renameFile(place_id,model.get('id'),new_name).done (data)->
										d= model.get('data')
										new_content=
											id:data.new_content_id
											data:_.extend d,
												name:new_name
												relative_path:data.relative_path
										model.set(new_content)
								"itemview:content:delete":(itemView,model)=>
									FileManager.deleteFiles(place_id,View.collection,[model])
								"files:add":(files)=>
									files_array= _.map files,(item)=>
										return _.pick item,'name','path','size','type','lastModifiedDate'
									FileManager.fileUploadManagement(files_array,place_id,View.collection.superset())
						else
							dragAndDropManage(View, View.$el, null)
							###status:Read Only interactions###
							App.vent.trigger 'placeToolbar:changeActions',
								[
									{
										title:"downloadAll",
										ui_icon:'<div class="downloadAll"></div>',
										cb:()->
											models = View.getSelectedItems()
											FileManager.downloadFiles(place_id,models)
									}
								]
							View.listenTo View, 'contextmenu:delete',(models)=>
								@showReadOnlyMessage()
							View.on
								"itemview:content:rename":(itemView,model,new_name)=>
									@showReadOnlyMessage()
								"itemview:content:delete":(itemView,model)=>
									@showReadOnlyMessage()
								"files:add":(files)=>
									@showReadOnlyMessage()
						Backbone.history.navigate "#place/type/#{viewType}/#{place_id}"
						App.activityFeed.show View
		settingsPlace:(place_id)->
			place_info= _initPlaceContext(place_id,"item/settings")
			@currentPlace = place_id
			if not place_info.place
				@showPlacesActivity()
			Backbone.history.navigate "#place/#{place_id}/parameters"
			View = ViewFactory.buildSettingsView(place_id)
			View.on
				"place:delete":=>
					@deletePlace(place_id).done =>
						Backbone.history.navigate("place/",{trigger:true})
					.fail ->
						alert "an error occured while deleting the place"
				"place:show_contacts":=>
					@showPlacesContacts place_id, View
			App.activityFeed.show View

		deletePlace:(place_id)->
			place = DataManager.getPlace(place_id)
			if place == null or _.isUndefined(place)
				return alert('Error on deleting place (Place_id not found)')
			if place.get('owner_uid')==null
				dialog_message = dialogMessagesManager.getMessage("delete_place")
				confirm_button_text = "Delete"
			else
				dialog_message = dialogMessagesManager.getMessage("leave_place")
				confirm_button_text = "Leave"
			done = $.Deferred()
			View2 = ViewFactory.buildDialogBox(dialog_message, ["cancel",confirm_button_text])
			App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show View2
			View2.on "view:#{confirm_button_text}",->
				if App.activityFeed?.currentView?.onDeleteAction
					App.activityFeed.currentView.onDeleteAction()
					$("#p-main-column").addClass("p-transparent-column")
				setTimeout ()=>
					PlaceAPI.deletePlace(place_id).done ()=>
						$("#p-main-column").removeClass("p-transparent-column")
						DataManager.deletePlace(place_id)
						done.resolve()
					.fail ->
						App.activityFeed.currentView.onDeleteAction() if App.activityFeed?.currentView?.onDeleteAction
						$("#p-main-column").removeClass("p-transparent-column")
						failView = ViewFactory.buildDialogBox("Error occured when deleting the place", ['ok'] )
						App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show failView
						done.reject()
					View2.trigger 'close'
				,1000
			View2.on "view:cancel",->
				View2.trigger 'close'
			return done

		showPlacesSettings:->
			View = ViewFactory.buildPlacesSettingsView()
			View.on
				'itemview:place:delete':(itemView,place_id)=>
					@deletePlace(place_id)
				'itemview:place:modify':(itemView,place_id)->
			App.activityFeed.show View
			App.vent.trigger "placeToolbar:change",'settings',{item_id:'item/places'}

		showPlacesActivity:->
			App.vent.trigger "placeToolbar:change",'default',{item_id:'item/placeActivity',title:"places activity"}
			View = ViewFactory.buildDisplayView()
			if DataManager.isPlaceCollectionEmpty()
				App.activityFeed.show ViewFactory.buildEmptyView()
			else
				App.activityFeed.show View
			View.on 'itemview:place:click',(itemView,placeName)=>
				@selectPlace(placeName)
			View.on 'itemview:place:options',(itemView,placeName)=>
				@settingsPlace(placeName)
			View.on 'itemview:place:delete',(itemView,placeName)=>
				@deletePlace(placeName)

		showPlacesContacts:(place_id, layout)->
			View = ViewFactory.buildContactsView(place_id)
			layout.content.show View
			View.on 'itemview:place:contact:remove',(itemView,contact)=>
				PlaceAPI.removeAnsamberFromPlace(contact.get('uid'),place_id).done ()->
					View.collection.remove(contact)

		getAnsambers:(place_id)->
			return DataManager.getAnsambersUidArray(place_id || currentPlace)
		changeRequestStatus:(place_id,status)->
			PlaceAPI.changePlaceStatus(place_id,status).done (data)->
				place= DataManager.getPlace(place_id)
				if place?
					place.set 'status',data.status
			.fail (err)->
				alert err
		copyFileToPlace:(place_id, file_id, origin_place_id)->
			ContentAPI.copyContent(origin_place_id, place_id, file_id)
		addAnsamberToPlace:(user_id, user_name, place_id, place_name, owner)->
			if owner is null 
				@getAnsambers(place_id).done (ansambers)->
					if ansambers.indexOf(user_id) == -1
						View2 = ViewFactory.buildDialogBox("add " + user_name + " to place " + place_name, ["cancel", "add"])
						App.dialogRegion.setStyleOptions({borderClass:'p-border-blue'}).show View2
						View2.on "view:add":=>
							PlaceAPI.addAnsamberToPlace(user_id, place_id)
							View2.trigger 'close'
						View2.on "view:cancel":->
							View2.trigger 'close'
					else 
						View2 = ViewFactory.buildDialogBox("Contact already in this place", ["ok"])
						App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show View2
			else
				View2 = ViewFactory.buildDialogBox("You are not allowed to add contact in this place", ["ok"])
				App.dialogRegion.setStyleOptions({borderClass:'p-border-orange'}).show View2
				View2.on "ok":->
					View2.trigger 'close'
		markContentAsRead:(place,content)->
			if !content.get("read")
				ContentAPI.markAsRead(place.get("id"),content.get('id')).done ()->
					content.set('read',true)
					place.decrementBadge()
		markContentAsUnRead:(place,content)->
		showReadOnlyMessage:()->
			View=ViewFactory.buildInfoPopup("This is a read only place, you are not allowed to do any modifications into this place !")
			App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show View
	}
	return api
