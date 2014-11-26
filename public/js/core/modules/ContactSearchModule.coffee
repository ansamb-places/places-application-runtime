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
	'cs!backend_api/PlaceBackendAPI'
	'moment'
],(App,PlaceAPI,Moment)->
	#This is the SearchContact Module which permit to search ansamber from contacts
	#On init, DomElement is the searchinput where typeahead going to be instanciate
	#place_id is required to add ansamber in it
	#an optional cb can be used to trigger action on clicking on addButon
	_reinitialize=(dataSet,jsonCollection)->
		##fill dataset with new data collection and reinit it
		dataSet.local= jsonCollection.toJSON()
		dataSet.clear()
		dataSet.initialize(true)
	return init=(DomElement,place_id,addEl,cb)->
		selected= null
		contactsCollection= App.module('ContactsService').api.getDataManager().getContactFilteredCollection((model)->
			return model.get('status')=='validated')

		#reinit dataset if collection is modified
		contactsCollection.on 
			'add':=>
				_reinitialize(contacts,contactsCollection)
			'change':=>
				_reinitialize(contacts,contactsCollection)
			'remove':=>
				_reinitialize(contacts,contactsCollection)

		## Tokens where we search
		firstnameTokens =(d)->
			Bloodhound.tokenizers.whitespace(d.firstname);
		lastnameTokens =(d)->
			Bloodhound.tokenizers.whitespace(d.lastname);
		#uidTokens =(d)->
		#	Bloodhound.tokenizers.whitespace(d.uid);
		contacts= new Bloodhound({
			datumTokenizer: (d)->
				return firstnameTokens(d).concat(lastnameTokens(d))#.concat(uidTokens(d))
			queryTokenizer: Bloodhound.tokenizers.whitespace,
			local: contactsCollection.toJSON()
			})
		##initialize Bloodhound objects
		contacts.initialize()
		##apply typeahead to the DOM element
		DomElement.typeahead {highlight: true,hint:false},
			{
				name: 'Contacts',
				displayKey:(d)->
					return d.firstname+" "+d.lastname
				source: contacts.ttAdapter(),
				templates:
					suggestion: _.template("<p data-no-dropdown-close='true' ><%-firstname%> <%-lastname%></p>")
					empty: ['<div class="empty-message">','no Contact match','</div>'].join('\n')
			}
		.on "typeahead:selected",(e,suggestion,dataset)=>
			if addEl
				selected= suggestion.uid
				addEl.show()
		DomElement.keyup (e)->
			if e.keyCode != 13
				addEl.hide()
		addEl.click (e)->
			e.preventDefault()
			if selected
				PlaceAPI.addAnsamberToPlace selected, place_id
			DomElement.typeahead('val', '')
			addEl.hide()
			selected= null
			cb and cb()


