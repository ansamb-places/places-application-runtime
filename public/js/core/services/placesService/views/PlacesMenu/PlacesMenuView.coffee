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
	'cs!./PlacesMenuItemView',
	'cs!./PlacesMenuEmptyView',
	'text!../../templates/placesMenu.tmpl'
],(View,EmptyView,tmpl)->
	return class PlaceMenuView extends Backbone.Marionette.CollectionView
		tagName:'ul'
		className: ''
		itemView:View
		emptyView: EmptyView
		_initialEvents:->
			super()
			# as we are using a filtered collection, we have to listen to the original collection reset
			# to call the Marionette logic instead of the one emitted on the filtered collection
			# because this one is always triggered on each add event just to apply the filter
			@stopListening @collection,"reset"
			@listenTo @collection.superset(),"reset",@render
		initialize:(options)->
			@listenTo @, 'file.watcher:copying', @inProgress
			@listenTo @, 'itemview:place:select', @setCurrentMenu
			# @listenTo @collection, 'change', @test

		setCurrentMenu:(itemView,model)->
			@collection.each (el)->
				if el.get('id')!=model.get('id')
					el.set 'selected',false
		inProgress:(place_id)->
			@children.findByModel(@collection.findWhere({id: place_id})).onCopying()