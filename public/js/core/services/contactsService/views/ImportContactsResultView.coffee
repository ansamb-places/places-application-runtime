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
	'cs!./ImportContactsResultItemView'
	'cs!backend_api/ContactBackendAPI'
],(itemView,ContactBackendAPI)->
	class FullScreenView extends Backbone.Marionette.SelectableListView
		className: 'p-single-content-page p-full-page'
		header:[
			{text:'email',class:"sorters",sorter:'email'}
			{text:'name',class:"sorters extra-large-size",sorter:'name'}
			{text:'latname',class:"sorters extra-large-size" ,sorter:'firstname'}
			{text:'',class:"large-size"}
		]
		multiselectMenu:[
			{title:'all',cmd:'all'}
			{title:'none',cmd:'none'}
		]
		tableClassName:"p-contact-import-table"
		itemView:itemView
		initialize:(options)->
			@collection= new Backbone.Collection
			@emails= options.emails
			@checking=true ## is searching contact
			super(options)
			@dragAndDrop=true

			@listenTo @,'multiselect:item:removed',@onItemUnSelected
			@listenTo @,'multiselect:item:added',@onItemSelected
			@listenTo @,'multiselect:items:removed',@onItemsUnSelected
			@listenTo @,'multiselect:items:added',@onItemsSelected

			@listenTo @,'itemview:contact:add',@onAddContact

			@listenTo @,'dropdown:all:click',=>@toggleGlobalSelect(true)
			@listenTo @,'dropdown:none:click',=>@toggleGlobalSelect(false)
		isEmpty:(collection)=>
			$empty_message = @$el.find(".empty_message")
			$empty_message.html('no more contact to add <div><span class="p-leave p-button-round p-background-grey p-button-padding p-ng-request-cancel">leave</span></div>')
			$table = @$el.find(".#{@tableClassName}")
			if collection.length == 0 and !@checking
				$empty_message.removeClass("hide")
				$table.addClass("hide")
			else
				$empty_message.addClass("hide")
				$table.removeClass("hide")
				return false
		onRender:=>
			setTimeout ()=>
				@checkContacts()
			,0
		onAfterItemAdded:(itemView)->

		checkContacts:()->
			$loading= $(
				"<div class='center'><span data-icon='l' class='p-loading p-color-contact p-big'></span></div>"
			)
			@$el.append $loading
			@$el.append('<div class="center"><span class="p-leave p-button-round p-background-grey p-button-padding p-ng-request-cancel">leave</span></div>')
			promises=[]
			_.each @emails,(email)=> 
				promises.push ContactBackendAPI.searchContact(email).done (contact)=>
					if contact
						contact.email= email
						@collection.add(contact)
			$.when.apply(@,promises).done ()=>
				@checking=false;
				$loading.remove()
				@checkEmpty()
			.fail ()->
				$loading.replaceWith("fail to check some contacts")

		events:
			"click .sorters":"sortBy"
			"click .p-leave":"leave"
		sortBy:(e)=>
			e.preventDefault()
			target = $(e.currentTarget)
			sortField = $(e.currentTarget).data('sorter')
			if target.hasClass('asc')
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('dsc')
			else 
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('asc')
			@collection.comparator= (model,model2)->
				m1 = model.get(sortField) || ""
				m2 = model2.get(sortField) || ""
				if sortField == 'data.mdate'
					m1 = moment(m1).format('X')
					m2 = moment(m2).format('X')
				if typeof m1 == "string"
					m1= m1.toLowerCase()
				if typeof m2 == "string"
					m2= m2.toLowerCase()
				return 0 if m1 == m2
				if target.hasClass 'dsc'
					return 1 if m1 < m2
					return -1 if m1 > m2
				else
					return 1 if m1 > m2
					return -1 if m1 < m2
			@collection.sort()
		
		onAddContact:(itemView,contact_obj)->
			itemView.ui.button.find('a').replaceWith("<span>invited</span>")
			setTimeout ()=>
				itemView.$el.fadeOut 400,()=>
					@collection.remove contact_obj
			,2000

		leave:()->
			@trigger 'action:leave'


