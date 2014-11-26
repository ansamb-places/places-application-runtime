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
	'text!../../templates/placesMenuItem.tmpl',
	'tiptip'
	'cs!backend_api/ContentBackendAPI'
	],(tmpl, _tiptip, ContentBackendAPI)->
	class PlacesMenuItemView extends Backbone.Marionette.ItemView
		tagName:'li'
		initialize:(options)->
			@listenTo @model,'change:selected',@changeSelected
			@listenTo @model, 'change:status change:name', @render
			@listenTo @model, 'change:unreadCount', @renderBadge
			super options
		template:=>
			data = @model.toJSON()
			return _.template tmpl,data
		events:
			'click':'onClick'
		onClick:(e)->
			$(".off-canvas-wrap").removeClass("move-right") #close Menu Bar
			@trigger 'place:click',@model.get('id')
			#@emptyBadge()
		onCopying:(e)->
			@$el.find(".place_loading").show 1000, ()->
				this.style.display = 'none'
		changeSelected:(model,selected)->
			if selected
				@$el.addClass 'selected'
				@trigger "place:select",model
			else
				@$el.removeClass 'selected'

		onRender:->
			@$el.droppable
				scope:'places-draggable'
				hoverClass:"p-dropOverlay"
				tolerance:"intersect"
				over:(event,ui)=>
					type = ui.helper.data('type')
					if type is 'ansamber'
						ui.helper.showAddIcon(true)

				drop:(event,ui) =>
					type = ui.helper.data('type')
					switch type
						when 'file'
							origin_place_id = ui.helper.data('place_id')
							files = ui.helper.data("files")
							if origin_place_id != @model.id
								_.each files,(file)=>
									@trigger "place:new_file",@model.id,file.id,origin_place_id
						when 'ansamber'
							@trigger "place:addAnsamberToPlace",ui.draggable.data('uid'),ui.helper.data('fullName'),@model.id, @model.get('name'), @model.get('owner_uid')

				out:(event,ui)=>
					type = ui.draggable.data('type')
					if type is 'ansamber'
						ui.helper.showAddIcon(false)
			@syncBadge()
		changeName:(model)=>
			@$el.find(".p-menu-name").text(' <span class="p-menu-item">' + model.escape('name') + '</span>')
		emptyBadge:->
			ContentBackendAPI.markAllAsRead(@model.id).done ()=>
				@model.set 'unreadCount', 0
				@renderBadge()
		syncBadge:->
			ContentBackendAPI.getUnreadContent(@model.get('id')).done (count)=>
				@model.set 'unreadCount',count
				@renderBadge()
		renderBadge:->
			badge= @$el.find(".place-notification")
			count = @model.get('unreadCount')
			if count > 99
				badge.text '99' # three digit numbers can't be displayed in the notification span
			else 
				badge.text count
			if count > 0
				badge.show()
			else badge.hide()
