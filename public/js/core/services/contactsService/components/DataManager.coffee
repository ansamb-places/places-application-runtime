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
	'cs!../entities/Contacts',
	'backbone-filtered-collection',
	'cs!modules/CollectionCloneHelper'
	'cs!backend_api/ContactBackendAPI'
],(Contacts,FilteredCollection,CloneHelper,ContactBackendAPI)->
	class DataManager
		constructor:->
			@contacts = new Contacts.collection
			@contacts.fetch
				success:->
					ContactBackendAPI.syncStatus()
		getContactCollection:->
			return @contacts
		getContactCollectionClone:(filter)->
			models = @contacts.where(filter)
			collection = new Contacts.collection
			for model in models
				collection.add model.toJSON() #we don't want to be sticked with original events
			return collection
		addContact:(contact)->
			c = new Contacts.model contact
			@contacts.add c
			# c.save()
		getContactById:(contact_id)->
			@contact.findWhere({id:contact_id})
		getContactFilteredCollection:(filter)->
			filteredContact = new FilteredCollection @contacts
			if filter?
				filteredContact.filterBy('filter',filter)
			return filteredContact
		getClonedContactCollection:()->
			CloneHelper.clone @contacts
		getAnsamberFromUid:(uids)->
			ansamber= null
			if _.isArray uids
				ansamber= []
				_.each uids,(uid)=>
					ansamber.push @contacts.findWhere({uid:uid})
			else 
				ansamber= @contacts.findWhere({uid:uids})
			return ansamber
	return new DataManager