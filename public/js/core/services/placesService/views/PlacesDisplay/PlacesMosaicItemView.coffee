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
define ['text!../../templates/placesMosaicItem.tmpl'],(tmpl)->
	class ItemRowView extends Backbone.Marionette.ItemView
		tagName:'li'
		colors:['yellow','teal','red','blue']
		initialize:(options)->
			@listenTo @model,'change:selected',@changeSelected
			@template = _.template tmpl
		render:->
			data = @model.toJSON()
			rand = (Math.floor((Math.random()*100)))%@colors.length
			data.color = @colors[rand]
			@$el.html @template(data)
			@
		events:
			'click':'onClick'
			'click .place_options':'place_options'
			'click .place_delete':'place_delete'
		onClick:(e)->
			e.stopPropagation()
			@trigger 'place:click',@model.get('id')
		place_options:(e)->
			e.stopPropagation()
			@trigger 'place:options',@model.get('id')
		place_delete:(e)->
			e.stopPropagation()
			@trigger 'place:delete',@model.get('id')
		changeSelected:(model,selected)->
			if selected==true
				@$el.addClass 'selected'
			else
				@$el.removeClass 'selected'