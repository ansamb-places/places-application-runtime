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
###ViewFactory
Build Views with collections from DataManager
###
define [
	'cs!../views/HomeView',
	'cs!../views/NGHomeView',
	'cs!../views/LoadingView',
	'cs!../views/layouts/PlacesMenuLayout',
	'cs!../views/layouts/SettingsLayout',
	'cs!../components/DataManager',
	'cs!../views/PlacesMenu/PlacesMenuView',
	'cs!../views/CreateView',
	'cs!../views/ActivityFeedView',
	'cs!../views/ParamsView',
	'cs!../views/EmptyView',
	'cs!../views/PlacesHeaderSearchView',
	'cs!../views/PlacesDisplay/PlacesDisplayView',
	'cs!modules/ViewLoader',
	'cs!../views/DefaultItemView',
	'cs!../views/PlacesRequestsView',
	'cs!common/views/DialogBoxView',
	'cs!../views/PlacesSettings/PlacesSettingsView',
	'cs!../views/PlacesContacts/ContactsView',
	'cs!../views/PlaceAnsambersDD/PlaceAnsambersDDView',
	'cs!app'
],(HomeView,NGHomeView,LoadingView,MenuLayout,SettingsLayout,
DataManager,PlacesMenuView,CreateView,ActivityFeedView,ParamsView,
EmptyView,PlacesHeaderSearchView,PlacesDisplayView,ViewLoader,DefaultItemView,
PlacesRequestsView,DialogBoxView,PlacesSettingsView,ContactsView, PlaceAnsambersDDView,App)->
	getPrimaryContentType=(content_type)->
		regexp= /^(.*):/
		result= regexp.exec(content_type)
		return if result then result[1] else content_type
	return {
		buildHomeView:->
			return new HomeView
		buildNGHomeView:->
			ng_contact:null
			ng_place:null
			View= new NGHomeView({loading:true})
			return View
		buildLoadingView:->
			return new LoadingView
		buildPlacesMenuView:(cb)->
			layout = new MenuLayout()
			layout.render()
			Places_listView = new PlacesMenuView {collection: DataManager.getFilteredPlacesCollection((model)->
				status=model.get('status')
				return status!="pending" and status.indexOf(':') ==-1
			)}
			RequestsView= @buildPlacesRequestsView()
			Places_listView.on 'after:item:added',cb
			layout.on 'render',()=>
				layout.places_list.show Places_listView
				layout.placesRequests.show RequestsView
				layout.$el.find('.split').foundation('dropdown')
				#layout.otherplaces.show View
			layout.notifyView = (event, place_id)->
				MyPlacesView.trigger event, place_id
			#layout.myplaces.show View
			#layout.otherplaces.show new PlacesMenuView {collection: DataManager.getPlaceCollection()}
			return {layout:layout,view:Places_listView}
		buildMyPlacesMenuView:->
			return new PlacesMenuView {collection: DataManager.getPlaceCollection()}
		buildCreateView:->
			return new CreateView
		buildActivityFeedView:(place_id)->
			place = DataManager.getPlace(place_id)
			ansambersCollection = DataManager.getAnsambers(place_id)
			return new ActivityFeedView {ansambers:ansambersCollection,currentPlace: place_id,placeName:place.get('name'),owner:place.get('owner_uid')}
		buildSettingsView:(place_id)->
			layout = new SettingsLayout()
			return layout
		buildEmptyView:()->
			return EmptyView
		buildDisplayView:()->
			return new PlacesDisplayView {collection: DataManager.getPlaceCloneFilteredCollection()}
		buildHeader:(type)->
			return new PlacesHeaderSearchView
		buildFullScreenView:(place,viewType,name,type)->
			done= $.Deferred()
			ViewLoader.getView name,'list',(View)->
				ansambersCollection = DataManager.getAnsambers(place.id)
				contents = DataManager.getFilteredContentCollection place.id,(model)->
					return true if (getPrimaryContentType(model.get('content_type')) == type)
				,true
				done.resolve(new View {viewType:viewType,place:place,collection:contents, ansambers:ansambersCollection})
			return done.promise()
		buildPlacesSettingsView:()->
			return new PlacesSettingsView {collection: DataManager.getPlaceCloneFilteredCollection()}
		buildDefaultItemView:()->
			return new DefaultItemView
		buildPlacesRequestsView:()->
			return new PlacesRequestsView {collection:DataManager.getFilteredPlacesCollection (model)->
				return model.get('status') == "pending"
			}
		buildInfoPopup:(message)->
			return new DialogBoxView {message:message,actions:['OK']}
		buildConfirmDeleteDialogBox:()->
			return new ConfirmDeleteDialogBox
		buildContactsView:(place_id)->
			ansambersCollection = DataManager.getAnsambers(place_id)
			return new ContactsView {collection:ansambersCollection}
		buildDialogBox:(message, actions, options)->
			return new DialogBoxView {message:message, actions:actions, options:options}
		buildPlaceAnsambersDDView:(place_id,owner)->
			Ansambers= DataManager.getAnsambers(place_id,{
				comparator: (item,item2)->
					status1= item.get('status')
					status2= item2.get('status')
					field1= item.get('firstname').toLowerCase()
					field2= item2.get('firstname').toLowerCase()
					field1= item.get('uid').toLowerCase() if field1 == ""
					field2= item2.get('uid').toLowerCase() if field2  == ""

					if status1 == status2 and field1 == field2
						return 0
					else if (status1=="pending" and status2=='validated') or ((status1 == status2) and field1 < field2)
						return -1 
					return 1
				})
			return new PlaceAnsambersDDView {collection: Ansambers,place_id:place_id,placeOwner:owner}
	}

	
