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
#This view display a conversation with ansambers and last posted content
#Empty conversation are not displayed
define [
	'text!../templates/messageNotificationItem.tmpl'
	],(tmpl)->
	class MessageNotificationItemView extends Backbone.Marionette.ItemView
		template: _.template tmpl
		tagName: 'li'
		className: 'notif'
		initialize:->
			@listenTo @model,"change",@render
		serializeData:->
			model_json = @model.toJSON()
			if model_json.last_content != null
				data = {type:null,text:""}
				#TODO this logic has to be managed by applications through a view or a template
				if model_json.last_content.content_type=="file"
					data = 
						type:model_json.last_content.content_type
						text:model_json.last_content.data.name
				else if model_json.last_content.content_type=="post"
					data =
						type:model_json.content_type
						text:model_json.last_content.data.post
				owner_ansamber= _.findWhere model_json.ansambers,{uid:model_json.last_content.owner}
				if owner_ansamber
					model_json.last_content = 
						owner_letter: owner_ansamber.firstname[0]
						data:data
				else 
					model_json.last_content = 
						owner_letter: "M"
						data:data
				return model_json
		render:->
			@isClosed = false
			@triggerMethod("before:render", @)
			@triggerMethod("item:before:render", @)
			if @model.get('last_content')?
				if @model.get('ansambers').length == 0
					@trigger 'ansamber:get',@model.get('id'),(ansambers)=>
						@model.set('ansambers', ansambers,{silent:true})
						@$el.html @template(@serializeData())
				else
					@trigger 'contact:get',@model.get('ansambers'),(contacts)=>
						ansambers= @model.get('ansambers')
						_.each contacts,(item,index)=>
							if item?
								ansambers[index].firstname= item.get('firstname')
								ansambers[index].lastname= item.get('lastname')
						@model.set('ansambers',ansambers)
						@$el.html @template(@serializeData())
			@bindUIElements()
			@triggerMethod("render", @)
			@triggerMethod("item:rendered", @)
			@
		onRender:->
			return @$el.hide() if @model.get('last_content') == null
			@$el.show()
			unless @model.get('last_content').read
				@$el.addClass 'unread'
			else
				@$el.removeClass 'unread'
		events:
			"click":"onClick"
		onClick:(e)->
			e.preventDefault()
			@trigger "action:show_history",@model.get('id')