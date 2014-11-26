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
	'moment'
],(App,Moment)->
	_reinitialize=(dataSet,jsonCollection)->
		##fill dataset with new data collection and reinit it
		dataSet.local= jsonCollection.toJSON()
		dataSet.clear()
		dataSet.initialize(true)
	return init=()->	
		tag= '#p-search-input'
		placesCollection= App.module('PlacesService').api.getDataManager().getFilteredPlacesCollection (model)->
			status=model.get('status')
			return status!="pending" and status.indexOf(':') ==-1
		placesCollection.on
			'add':=>
				_reinitialize(places,placesCollection)
			'remove':=>
				_reinitialize(places,placesCollection)
			'change':=>
				_reinitialize(places,placesCollection)
		filter = (item)->
			item.get('status')=="validated" and item.get('conversation_id') != null
		contactsCollection= App.module('ContactsService').api.getDataManager().getContactFilteredCollection(filter)
		contactsCollection.on
			'add':=>
				_reinitialize(contacts,contactsCollection)
			'remove':=>
				_reinitialize(contacts,contactsCollection)
			'change':=>
				_reinitialize(contacts,contactsCollection)
		firstnameTokens =(d)->
			Bloodhound.tokenizers.whitespace(d.firstname);
		lastnameTokens =(d)->
			Bloodhound.tokenizers.whitespace(d.lastname);
		#uidTokens =(d)->
		#	Bloodhound.tokenizers.whitespace(d.uid);
		places= new Bloodhound({
			datumTokenizer: (d)->
				return Bloodhound.tokenizers.whitespace(d.name)
			queryTokenizer: Bloodhound.tokenizers.whitespace,
			local: placesCollection.toJSON()
			})
		contacts= new Bloodhound({
			datumTokenizer: (d)->
				return firstnameTokens(d).concat(lastnameTokens(d))#.concat(uidTokens(d))
			queryTokenizer: Bloodhound.tokenizers.whitespace,
			local: contactsCollection.toJSON()
			})
		##initialize Bloodhound objects
		places.initialize()
		contacts.initialize()
		##apply typeahead to the DOM element
		$(tag).typeahead {highlight: false},
			{
				name: 'Contacts',
				displayKey:(d)->
					return d.firstname+" "+d.lastname
				source: contacts.ttAdapter(),
				templates: 
					header: '<h3 class="p-search-header contact-header">Contacts</h3>'
					empty: ['<div class="empty-message">','No Contact found','</div>'].join('\n')
					suggestion: _.template("<p class='suggestion' data-no-dropdown-close='true' ><%-firstname%> <%-lastname%></p>")
			},
			{
				name: 'Places'
				displayKey: 'name'
				source: places.ttAdapter()
				templates: 
					header: '<h3 class="p-search-header place-header">Places</h3>'
					empty: ['<div class="empty-message">','No Place found','</div>'].join('\n')
					suggestion: _.template("<p class='suggestion' ><%-name%> <span class='last-update-suggestion'>(<%if(owner_uid!=null) print(owner.firstname+' '+owner.lastname); else print('me')%>, <%-moment(created_at).fromNow()%>)</span></p>")
			}
		.on "typeahead:selected",(e,suggestion,dataset)->
			if dataset=='Contacts'
				App.module('ConversationsService').api.getController().show_conversation_with(suggestion,'chatbox')
			if dataset=='Places'
				App.module('PlacesService').api.getController().showFullScreen("list",suggestion.id)
			$(tag).typeahead('val', '')
