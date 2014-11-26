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
	'cs!./DataManager'
	'cs!../views/ContactListView'
	'cs!../views/AddContactView'
	'cs!../views/SelectContactView'
	'cs!../views/ManageContactsView'
	'cs!../views/ContactsRequestsView'
	'cs!../views/layouts/ContactsMenuLayout'
	'cs!../views/ImportContactsView'
	'cs!../views/ImportContactsResultView'
],(DataManager,ContactListView,AddContactView,SelectContactView,
ManageContactsView,ContactsRequestsView,ContactsMenuLayout,
ImportContactsView,ImportContactsResultView)->
	return {
		buildRightContactBarView:(cb)->
			layout = new ContactsMenuLayout()
			layout.render()
			Contacts_listView= @buildContactListView()
			RequestsView= @buildRequestsView()
			Contacts_listView.on 'after:item:added',(itemView)->
				cb itemView
			layout.on 'render',()=>
				layout.contactsList.show Contacts_listView
				layout.contactsRequests.show RequestsView
			return {layout:layout,view:Contacts_listView}
		buildContactListView:->
			return new ContactListView {collection:DataManager.getContactFilteredCollection((model)->
				return model.get('status')=='validated')}
		buildAddContactView:->
			return new AddContactView
		buildSelectContactView:->
			collection = DataManager.getContactCollectionClone {'status':'validated'}
			collection.forEach (model)->
				model.set 'disabled',false
			return new SelectContactView {collection:collection}
		buildManageContactsView:->
			return new ManageContactsView {collection:DataManager.getClonedContactCollection()}
		buildRequestsView:->
			return new ContactsRequestsView {collection: DataManager.getContactFilteredCollection((model)->
				return model.get('status')=='pending')}
		buildImportContactsView:->
			return new ImportContactsView 
		buildImportContactsResult:(emails)->
			return new ImportContactsResultView {emails:emails}
	}