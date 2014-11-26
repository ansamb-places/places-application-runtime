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
	'text!../templates/RightContactBarItem.tmpl'
	'cs!modules/interactions/JqueryUIDragAndDropManager'
],(tmpl, JqueryUIDragAndDropManager)->
	return class ItemView extends Backbone.Marionette.ItemView
		tagName:'li'
		className:'draggable contact'
		initialize:->
			@listenTo @model,'change',@render
		template:(model)->
			return _.template tmpl,model
		events:
			'click':'onClick'
			'click .trigger':'actionTrigger'
		serializeData:->
			data = @model.toJSON()
			if typeof data.aliases == "undefined" or data.aliases == null
				data.aliases = {alias:'n/a'}
			return data 
		onRender:->
			@$el.draggable
				zIndex:999
				appendTo:'body'
				cursor: 'move'
				cursorAt:
					top:25
					left:35
				scope:'places-draggable'
				containment:'parent'
				helper:=>
					helper = $("<div class='p-contact-hover'> add " + @model.escape('firstname') + " " + @model.escape('lastname') +
						"<div class='p-round-hover'>+</div></div>")
					helper.data('fullName', @model.escape('firstname') + " " + @model.escape('lastname') )
					helper.data('type','ansamber')
					helper.data('uid',@model.get('uid'))
					helper
				start:(event, ui)=>
					ui.helper.showAddIcon=(show)->
						@count = 0 if !@count?
						if show then @count++ else @count--
						if @count <= 0
							ui.helper.find(".p-round-hover").hide()
							@count = 0
						else 
							ui.helper.find(".p-round-hover").show()
			@$el.droppable
				scope:"places-draggable"
				tolerance:"intersect"
				over:(event, ui)=>
					switch ui.helper.data('type') 
						when 'file','files'
							@$el.addClass "p-dropOverlay"
				drop:(event, ui)=>
					type = ui.helper.data('type')
					switch type
						when 'file'
							source_place_id = ui.helper.data('place_id')
							ansamber = @model.toJSON()
							files = ui.helper.data('files')
							_.each files,(file)=>
								@trigger "contact:sendFileFromPlace", file.id, source_place_id, ansamber
							@$el.removeClass("p-dropOverlay")
				out:(event, ui)=>
					@$el.removeClass("p-dropOverlay")
			@$el.find('[title]').tooltip({
				show:false,
				hide:false,
				content:()->
					$(@).prop('title')
				position:
					my: "left top", at: "right top"
				tooltipClass: 'p-tooltip'
			})
		onClick:->
			if @model.get('conversation_id') == null
				alert "You can't speak with this contact, Sorry :/"
			else
				@trigger 'contact:click',@model.toJSON()
		actionTrigger:(e)->
			action = $(e.currentTarget).data('action')
			@trigger "contact:#{action}",@model.get('uid')
		getBadgeEl:->
			return @$el.find(".message-notification")
		setBadgeValue:(value)->
			badge = @getBadgeEl() 
			return if not _.isNumber value
			badge.html value
			if value==0
				badge.hide()
			else badge.show()
