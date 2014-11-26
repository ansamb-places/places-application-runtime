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
	'async',
	'cs!modules/ApplicationManager',
	'cs!regions/DialogRegion',
	'cs!regions/CustomDialogRegion',
	'cs!regions/ConferenceRegion',
	'cs!regions/MultiViewRegion',
	'cs!modules/EventsManager',
	'cs!modules/AvatarUpdater'
	"cs!backend_api/AccountBackendAPI",
	'linkChecker',
	"cs!modules/UIDragAndDropPrevent"
]
,(async,ApplicationManager,DialogRegion,CustomDialogRegion,ConferenceRegion,
MultiViewRegion,EventsManager,AvatarUpdater, AccountAPI, linkChecker, UIDragAndDropPrevent)->

	### handle server link disconnections ###
	EventsManager.on 'server_link:status:change',(new_status)->
		if new_status == "disconnected"
			linkChecker.setLinkStatus(false)
		else
			linkChecker.setLinkStatus(true)

	### Marionnette application settings ###
	window.mainApp = App = new Backbone.Marionette.Application()
	window.ondragover = (e) ->
		e.preventDefault()
	window.ondrop = (e) ->
		e.preventDefault()
	App.addRegions
		placesMenu:"#placesMenu"
		placesContacts:"#placesContacts"
		contactsRequests:"#contactsRequests"
		downloads:"#downloads"
		nbDownloads:"#nbDownloads"
		placesContainer:"#placesContainer"
		placeToolBar:"#p-place-title"
		activityFeed:"#activityFeed"
		mainRegion:"#main-section"
		leftRegion:"#main-places"
		rightRegion:"#contacts-right"
		header:"#area_header"
		stackedChatBoxes:"#stackedChatBoxes"
		chatBoxes:MultiViewRegion.extend({el:'#chatBoxes'})
		popupRegion:DialogRegion.extend({el:'#popupRegion'})
		dialogRegion:CustomDialogRegion.extend({el:'#dialogRegion'})
		conferenceRegion:ConferenceRegion.extend({el:'#conferenceRegion'})

	initLoadDone = new Promise()

	currentPlace = "default"
	App.addInitializer (options)->
		AvatarUpdater.initDynamicUpdate()
		currentPlace = options.placeName if options.placeName
		App.reqres.setHandler "get:currentPlace",()->
			return currentPlace

		async.parallel
			#load applications config
			applicationManager:(callback)->
				ApplicationManager.get().then (instance)->
					callback null,instance
			# contents:(callback)->
			# 	contents.setPlaceName options.placeName
			# 	contents.fetch().done ->
			# 		callback null,contents
		,(err,results)->
			initLoadDone.resolve results
	if process?
		process.on 'uncaughtException' ,(err)->
			console && console.error('uncaughtException:', err)
			console && console.error(err.stack)

		window.addEventListener 'error' ,(errEvent)->
			m= ''
			console and console.error(errEvent)
			m = 'uncaughtException: '  +errEvent.message + '\nfilename:"' +'", line:' + errEvent.linenodocument.write('<pre><h2>' +m + '</h2><div style="color:white;background-color:red">' +errEvent.error.stack + '</div></pre>')
			alert(m)
	App.on "initialize:after",->
		initLoadDone.then (datas)->
			require [
				"cs!services/placesService/index"
				"cs!services/contactsService/index"
				"cs!services/conversationsService/index"
				"cs!services/accountService/index"
				"cs!services/notificationService/index"
				"cs!services/updateService/index"
				"cs!modules/SearchBarModule"
				'cs!common/views/PlaceToolbarView'
				"cs!modules/shortcutsManager/ShortcutsManager"
				"cs!services/conferenceService/index"
				"cs!services/devicesService/index"
				'cs!modules/SystemNotifier'
			]
			,(PlacesService,ContactsService,ConversationsService,accountService,notificationService,updateService,SearchBarModule,SystemNotifier)->
				# ContactApp.start({applicationManager:datas.applicationManager})
				###App.commands.setHandler "set:currentPlace",(name)->
					currentPlace = name
					WallApp.start({applicationManager:datas.applicationManager})
					WallApp.setCurrentPlace name###
				$.when(
					PlacesService.ready,
					ContactsService.ready,
					ConversationsService.ready,
					accountService.ready,
					notificationService.ready,
					updateService.ready
				).done ()->
					AccountAPI.getProfile().done (profile)->
						$('#p-profile-name').text(profile.firstname + " " + profile.lastname)
						# trick to force the DOM element to be reflowed and get the right width
						$('#p-profile-name').hide 0,->$('#p-profile-name').show(0)
					Backbone.history.start()
					Backbone.history.navigate("place/",{trigger:true}) if Backbone.history.fragment == ""
					SearchBarModule()
					UIDragAndDropPrevent.preventDrag()
					window.bootLoader.hide() if window.bootLoader

	return App
