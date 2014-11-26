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
	'text!../templates/contactsRequests.tmpl'
],(tmpl)->
	class ContactsRequestsView extends Backbone.Marionette.View
		tagName: 'div'
		className: 'p-request'
		index: null
		currentModel= null
		displayed:false
		initialize:(options)->
			@collection=options.collection
			@listenTo @collection,'add',@onAfterItemAdded
			@listenTo @collection,'remove',@onItemRemoved
		render:->
			@$el.html tmpl
			if @collection.length > 0
				@showRequests()
				@displaycontactRequest(0)
			else 
				@hideRequests()
			@
		onItemRemoved:(options)->
			if @collection.length == 0
				@index= null
				@currentModel= null
				@$el.find('.p-number-request').empty()
				@$el.find('.p-request-number').empty()
				@$el.find('.p-request-name').empty()
				@hideRequests()
				return
			@displaycontactRequest(@index-1)
		onAfterItemAdded:()->
			return if @collection.length == 0
			if @index==null
				@showRequests()
				@displaycontactRequest(0)
		displaycontactRequest:(index)->
			model= @collection.at(index)
			if model?
				@currentModel= model
				@index= index
			else 
				if index>@index
					@currentModel= @collection.at(0)
					@index= 0
				else if index<@index
					@index= @collection.length-1
					@currentModel= @collection.at(@index)
			@$el.find('.p-number-request').text '+'+@collection.length
			@$el.find('.p-request-number').text @index+1
			@$el.find('.p-request-name').text @currentModel.escape('firstname')+" "+@currentModel.escape('lastname')
			if @currentModel.get('aliases').alias?
				@$el.find('.p-request-alias').text @currentModel.get('aliases').alias
			else
				@$el.find('.p-request-alias').text 'n/a'
		events:
			"click .p-request-next":"nextRequest"
			"click .p-request-previous":"previousRequest"
			"click .p-request-accept":"acceptRequest"
			"click .decline":"declineRequest"
			"click .p-request-later":"laterRequest"
		showRequests:()=>
			@$el.show()
			@trigger "request:show"
			@displayed=true
		hideRequests:()=>
			@$el.hide()
			@trigger "request:hide"
			@displayed=false
		nextRequest:(e)->
			e.preventDefault()
			@displaycontactRequest(@index+1)
		previousRequest:(e)->
			e.preventDefault()
			@displaycontactRequest(@index-1)
		acceptRequest:(e)->
			e.preventDefault()
			@trigger "contact:accept",@currentModel.get('uid')
		declineRequest:(e)->
			e.preventDefault()
			@trigger "contact:reject",@currentModel.get('uid')
		laterRequest:(e)->
			e.preventDefault()
			@trigger "contact:later",@currentModel.get('uid')


