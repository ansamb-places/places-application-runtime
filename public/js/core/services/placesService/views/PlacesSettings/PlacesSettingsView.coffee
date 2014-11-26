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
	'text!../../templates/placesSettings.tmpl',
	'cs!./PlacesSettingsItemView'
	],(tmpl,ItemView)->
	return class View extends Backbone.Marionette.CompositeView
		tagName: 'div'
		className: 'p-single-content-page p-full-page'
		template:->
			return (tmpl)
		itemViewContainer: 'tbody'
		itemView: ItemView
		events:
			"click .sorters":"sortBy"
		initialize:(options)->
			@collection.comparator= "uid"
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
			@collection.superset().comparator= (model,model2)->
				m1 = model.get(sortField) || ""
				m2 = model2.get(sortField) || ""
				return 0 if m1 == m2
				if target.hasClass 'dsc'
					return 1 if m1 < m2
					return -1 if m1 > m2
				else
					return 1 if m1 > m2
					return -1 if m1 < m2
			@collection.superset().sort()
			@collection.trigger "reset"