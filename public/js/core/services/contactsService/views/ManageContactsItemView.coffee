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
define ['text!../templates/manageContactsItem.tmpl'],(tmpl)->
	return class ItemView extends Backbone.Marionette.ItemView
		tagName:'tr'
		className:''
		initialize:->
			@listenTo @model,'change',@render
		onRender:->
			@$el.find('.trigger').tooltip {
				show:false,
				hide:false,
				position:
					my: "left top", at: "right bottom"
				tooltipClass: 'p-tooltip'
			}
		template:(model)->
			return _.template tmpl,model
		serializeData:()->
			data = @model.toJSON()
			if data.aliases == null
				data.aliases = {alias:'n/a'}
			return data 
		events:
			'click .trigger':'actionTrigger'
		actionTrigger:(e)->
			action = $(e.currentTarget).data('action')
			@trigger "contact:#{action}",@model.get('uid')
