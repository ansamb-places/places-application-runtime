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
	'cs!./ConversationManager'
	'cs!backend_api/PlaceBackendAPI'
	'cs!backend_api/ContentBackendAPI'
	'cs!modules/interactions/dragAndDropSupport'
	'cs!entities/Contents'
	'cs!../entities/Conversations'
	'cs!modules/FileManager'
	'cs!../../../node-webkit/links'
],(App,ViewFactory,ConversationManager,PlaceBackendAPI,ContentBackendAPI,DragAndDrop,ContentEntities,Conversations,FileManager,nwlinks)->
	ConversationManager.setup(App.activityFeed.el,App.chatBoxes.el)
	#private methods
	createConversation = (place_id,ansambers,mode)->
		dd=null
		view = ViewFactory.buildChatBoxConversation place_id,ansambers,mode
		setDd=()->
			dd = new DragAndDrop {dom:view.$el,delegateEvent:view}
			dd.on "drag&drop",(data)->
				FileManager.fileUploadManagement(data.files,place_id,view.collection,{randomize:true})
		place = view.place 
		if place.get('status') == 'validated'
			setDd()
		place.on "change:status",()->
			dd.remove() if place.get('status') == 'disabled'
			setDd() if place.get('status') == 'validated'
		view.on
			'itemview:content:download':(itemView,file)->
				FileManager.downloadFiles(place_id,[file])
			'itemview:content:delete':(itemView,model)->
				FileManager.deleteFiles(place_id,view.collection,[model])
			'action:add_ansamber':(existing_ansamber_uids,cb)->
				#the request will be handlded by contactsService
				choiceView = App.reqres.request('ansamber:view:choice')
				choiceView.setDisabledElements existing_ansamber_uids
				choiceView.once 'selectedContacts',cb
				App.dialogRegion.setStyleOptions({borderClass:'p-border-contact'}).show choiceView
			'audio:call':(ansamber)->
				App.vent.trigger 'conversation:audio:call', ansamber
			'visio:call':(ansamber)->
				App.vent.trigger 'conversation:visio:call', ansamber
			'ansamber:uid':(uid,cb)->
				App.reqres.request "ansamber:uid:resolve", uid,cb
			'file:copy':(content_id,source_place_id,cb)->
				FileManager.copyFileToConversation place_id,content_id,source_place_id,cb
			'create:randomplace':(promise)->
				PlaceBackendAPI.createRandomPlace().done (place)=>
					view.switchPlaceName place.id
					conv= Conversations.findWhere({id:place.id})|| Conversations.add(place)
					view.place= conv
					promise.resolve()
				.fail (error)->
					promise.reject(error)
		view.collection.on 'add',(model)->
				#TODO manage errors
		#keep track of opened conversations to not reopen it and be able to push data
		ConversationManager.addConversation place_id,view
		return view

	return {
		#mode could be undefined (full screen mode) or equal to 'chatbox' (small floating window)
		show_conversation_with:(ansamber,mode,clicked)->
			done= $.Deferred()
			#TODO use place service API to get this information
			PlaceBackendAPI.getUniqueConversationPlace(ansamber.uid).done (response)=>
				place_id = response.id
				if not ConversationManager.isConversationExists place_id
					view = null
					#TODO lauch this request only if some unread contents exists and only for the concerned
					ContentBackendAPI.markAllAsRead(place_id).fail (err)->
						console.log "Error while setting contents as read:",err
					if mode=='chatbox'
						view = createConversation place_id,[ansamber],mode
						App.chatBoxes.show view,place_id
						ConversationManager.stackConversation()
					else
						#TODO implement full screen mode
						view = createConversation place_id,[ansamber],'full-screen'
						App.activityFeed.show view
				else 
					view= ConversationManager.getConversation place_id
				done.resolve(place_id,view)
				ConversationManager.setFocusOnConversation(place_id,true)
			.fail (error)->
				if typeof error == "string"
					alert(error)
				else
					alert(error.message)
				done.reject(error)
			return done.promise()

		show_conversation_by_id:(place_id,mode,options)->
			unless ConversationManager.isConversationExists place_id
				options ?= {}
				options = _.extend {focus:true},options 
				#TODO use place service API to get this information()
				PlaceBackendAPI.getAnsambersForPlace(place_id).done (ansambers)->
					ansambers_uid = _.map ansambers,(item)->item.uid
					view = null
					ContentBackendAPI.markAllAsRead(place_id).fail (err)->
						console.log "Error while setting contents as read:",err
					if mode=='chatbox'
						view = createConversation place_id,ansambers,mode
						App.chatBoxes.show view,place_id
						ConversationManager.stackConversation()
						view.focus() if options.focus
					else
						#TODO implement full screen mode
						view = createConversation place_id,ansambers,'full-screen'
						App.activityFeed.show view
					view.focus() if options.focus
				.fail (err)->
					alert 'An error occured when trying to open the conversation'
			else 
				ConversationManager.setFocusOnConversation(place_id,true)
		show_history:->
			View = ViewFactory.buildConversationsList()
			View.on 
				"itemview:action:show_history":(item,id)=>
					@show_conversation_by_id(id,'chatbox')
				'itemview:ansamber:get':(childItemView,place_id,cb)->
					PlaceBackendAPI.getAnsambersForPlace(place_id).done (ansambers)->
						cb ansambers
					.fail (err)->
						console.log "error on ansamber get"
						cb []
			App.activityFeed.show View
			App.vent.trigger "placeToolbar:change",'settings',{item_id:'item/conversations',title:"conversations"}
		send_file_to_contact:(content_id, source_place_id, ansamber)->
			@show_conversation_with ansamber, "chatbox"
			PlaceBackendAPI.getUniqueConversationPlace(ansamber.uid).done (response)=>
				place_id = response.id
				FileManager.copyFileToConversation place_id,content_id,source_place_id,(file)=>
					conv = ConversationManager.getConversation(place_id)
					conv.collection.onAfterFetch ()->
						conv.collection.add file
		conversation_settings:->

	}
