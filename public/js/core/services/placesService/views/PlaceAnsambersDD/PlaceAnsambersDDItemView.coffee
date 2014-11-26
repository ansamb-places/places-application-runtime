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
	"text!../../templates/PlaceAnsambersDDItem.tmpl"
	],(template)->
	class PlaceAnsambersDDItemView extends Backbone.Marionette.ItemView
		tagName: 'li'
		className: 'p-dropdown-ansamber-item'
		initialize:(options)->
			super(options)
			@listenTo @model,'change',@render
			@placeOwner= options.placeOwner || null
		serializeData:()->
			data = {}
			if @model
				data = @model.toJSON()
				data.placeOwner= @placeOwner
			return data
		template:(model)->
			return _.template template,model
		events:
			"click .p-ansambers-dropdown-delete":"deleteAnsamber"
		deleteAnsamber:(e)->
			e.preventDefault()
			@trigger "ansamber:delete",@model.get('uid')