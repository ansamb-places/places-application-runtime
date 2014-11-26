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
	'text!../templates/notif_template.tmpl'
	'cs!../components/notif_text_generator'
	'cs!backend_api/NotificationBackendAPI'
],(tmpl,generator,notificationAPI)->
	return class ItemView extends Backbone.Marionette.ItemView
		tagName:'li'
		className:''
		initialize:->
			@listenTo @model,'change',@render
		template:(model)=>
			tmpl_gen = generator[model.tag].template
			data_text = if _.isFunction tmpl_gen then tmpl_gen(model) else _.template tmpl_gen,model
			@action = generator[model.tag].action
			if @action=='' or @action==null
				@action = null
			else
				@action = _.template @action,model
			return _.template tmpl,{text:data_text,action:@action,json:model}
		onRender:->
			unless @model.get('read')
				@$el.addClass 'unread'
			else
				@$el.removeClass 'unread'
			clearInterval @interval if @interval?
			@interval = setInterval @updateTimeago.bind(@),60000
			@updateTimeago()
		updateTimeago:->
			@$el.find(".timeago").text moment.utc(@model.get('date')).fromNow(true)
		events:
			'click':'onClick'
		onClick:(e)->
			e.preventDefault() if @action==null
			notificationAPI.markAsRead(@model.get('id')).done =>
				@model.markRead()
				@trigger 'item:click' if @action?