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
	'ansamb_context',
	'text!template/conversation.tmpl',
	'moment'
],(c,tmpl,Moment)->
	class ConversationView extends Backbone.Marionette.ItemView
		tagName: 'span'
		className : 'file'
		# className:'animated fadeInRight'
		initialize:(options)->
			@place_id = options.place_id||"default"
			@template = _.template tmpl
			#to know if this view have to contact the application to get the content data
			@syncWithApp = @model.get('data')==null
			@listenTo @model,'change',@render
			c.socketio.on "#{@placeName}:message",(data)->
					alert JSON.stringify(data)
		serializeData:()->
			data= {}
			if @model
				data = this.model.format()
				data.date= Moment(data.date).format("ddd MM/DD/YY HH:mm")
			return data
		onRender:()->
			if @model.get('backend_synced') and @model.get('downloaded')
				@$el.find(".messages").addClass('p-downloadable')
				@delegateEvents()
			else @undelegateEvents()
		events:
			'click [data-action=download]' : 'download'
		download:(e)->
			@trigger "content:download", @model if (@model.get("downloaded") and @model.get("uploaded"))
		syncedChange:->
			if @model.get('content').owner == null
				@$el.addClass('self')
		updateTimeago:->
			@$el.find(".timeago").html moment.utc(@model.get('content.date')).fromNow()
	return ConversationView