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
	'text!template/post.tmpl',
	'cs!js/Model'
],(c,tmpl,Model)->
	class WallView extends Backbone.View
		tagName: 'span'
		className : 'messages'
		# className:'animated fadeInRight'
		initialize:(options)->
			@placeName = options.placeName||"default"
			@template = _.template tmpl
			#to know if this view have to contact the application to get the content data
			@syncWithApp = @model.get('data')==null
			@listenTo @model,'change:data.synced',@syncedChange
			c.socketio.on "#{@placeName}:message",(data)->
					alert JSON.stringify(data)
		render:=>
			@$el.empty()
			@$el.html "Loading ..."
			json = @model.toJSON()
			@$el.html @template(json)
		events:
			'click':'onClick'
			
		onClick:->
			console.log "content clicked"
		syncedChange:->
			console.log "model synced"
			if @model.get('content').owner == null
				@$el.addClass('self')
	return WallView