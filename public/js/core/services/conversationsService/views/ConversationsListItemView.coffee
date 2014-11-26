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
	'text!../templates/conversationsListItem.tmpl'
	],(tmpl)->
	class ConversationsListItemView extends Backbone.Marionette.ItemView
		template: _.template tmpl
		tagName: 'tr'
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
				model_json.last_content.data= data
			return model_json
		render:->
			if @model.get('ansambers').length == 0
				@trigger 'ansamber:get',@model.get('id'),(ansambers)=>
					@model.set('ansambers', ansambers,{silent:true})
					super()
			else 
				super()
		onRender:()->
			if @model.get('last_content')
				@updateTimeago()
				setInterval ()=>
					@updateTimeago()
				,60000
		events:
			"click":"onClick"
		onClick:(e)->
			e.preventDefault()
			@trigger "action:show_history",@model.get('id')
		updateTimeago:->
			@$el.find(".timeago").html moment.utc(@model.get('last_content').date).fromNow()