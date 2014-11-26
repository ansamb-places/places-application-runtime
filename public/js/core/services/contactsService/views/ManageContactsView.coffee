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
	'text!../templates/manageContacts.tmpl',
	'cs!./ManageContactsItemView'
	],(tmpl,ContactRowItemView)->
	return class View extends Backbone.Marionette.CompositeView
		tagName: 'div'
		className: 'p-single-content-page p-full-page'
		template:->
			return (tmpl)
		itemViewContainer: 'tbody'
		itemView: ContactRowItemView
		events:
			"click .sorters":"sortBy"
			'click .wtrigger':'actionTrigger'
		actionTrigger:(e)->
			action = $(e.currentTarget).data('action')
			@trigger "contact:#{action}",@collection.findWhere({selection:true})?.get('uid')
		initialize:(options)->
			@collection.comparator= "aliases.alias"
		onRender:()->
			@confirm_delete() if @collection.findWhere({selection:true})?
		sortBy:(e)=>
			e.preventDefault()
			target = $(e.currentTarget)
			sortField = $(e.currentTarget).data('action')
			if target.hasClass('asc')
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('dsc')
			else 
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('asc')
			@collection.comparator= (model,model2)->
				prop1 = model.get(sortField)
				prop2 = model2.get(sortField)
				if !prop1?
					prop1 = 'n/a'
				if !prop2?
					prop2 = 'n/a'
				m1 = prop1.toLowerCase()
				m2 = prop2.toLowerCase()
				return 0 if m1 == m2
				if target.hasClass 'dsc'
					return 1 if m1 < m2
					return -1 if m1 > m2
				else
					return 1 if m1 > m2
					return -1 if m1 < m2
			@collection.sort()
			@collection.trigger "reset"
		confirm_delete:()->
			@$el.find('.delete-contact').css( "display", "inline")
		cancel_delete:()->
			@$el.find('.delete-contact').hide()	