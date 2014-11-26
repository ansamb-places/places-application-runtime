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
	'cs!./PlacesMosaicItemView',
	'cs!./PlacesListItemView',
	'text!../../templates/placesDisplay.tmpl'
],(ThumbItem,ListItem,tmpl)->
	class PlacesRowComposite extends Backbone.Marionette.CompositeView
		itemView: ThumbItem
		itemViewContainer: '.placeView'
		className: 'activityFeed'
		itemViews:
			thumb:ThumbItem
			list:ListItem
		itemContainerClasses:
			thumb:"small-block-grid-2 medium-block-grid-3 large-block-grid-4"
			list:""
		sortTag:
			#comparators to sort collection
			most_recent:(model)->
				date = new Date(model.get('created_at'))
				return -date.getTime()
			alpha:'name'
		filterTag:
			myplaces_filter:{owner_uid:null}
			otherplaces_filter:
				owner_uid:(model)->
					return model != null
		template:->
			return tmpl
		onItemRemoved:(itemView)->
			if @collection.size() == 0
				@trigger 'collection:empty'
		ui:
			most_recent:"#most_recent"
			alpha:"#alpha"
			list:"#list"
			thumb:"#thumb"
		events:
			"click #most_recent":"sort"
			"click #alpha":"sort"
			"click #list":"view"
			"click #thumb":"view"
			"click #myplaces_filter":"filter"
			"click #otherplaces_filter":"filter"
		sort:(e)->
			target= $(e.target)
			if !target.hasClass('selected')
				@ui.alpha.removeClass('selected')
				@ui.most_recent.removeClass('selected')
				target.addClass('selected')
				@collection.sort(@sortTag[target.attr('id')])
				@collection.trigger 'reset'
		view:(e)->
			target= $(e.target)
			if !target.hasClass('selected')
				@ui.list.removeClass('selected')
				@ui.thumb.removeClass('selected')
				target.addClass('selected')
				@itemView = @itemViews[target.attr('id')]
				@$itemViewContainer.removeClass()
				@$itemViewContainer.addClass("mosaic")
				@$itemViewContainer.addClass(@itemContainerClasses[target.attr('id')])
				@collection.trigger 'reset'
		filter:(e)->
			target= $(e.target)
			if !target.hasClass('selected')
				_.each @filterTag,(item,key)=>
					$('#'+key).removeClass('selected')
					@collection.removeFilter(key)
				target.addClass('selected')
				@collection.filterBy(target.attr('id'), @filterTag[target.attr('id')]);
			else
				target.removeClass('selected')
				@collection.removeFilter(target.attr('id'))
				

		onClose:->
			@collection.unbind()
