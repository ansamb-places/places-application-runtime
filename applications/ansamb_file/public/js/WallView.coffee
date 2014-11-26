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
	'cs!js/ViewGetter',
	'cs!js/DownloadView'
	'moment',
	'cs!js/CollectionView'
],(c,vg,DownloadView,moment,CollectionView)->
	listenSocket = (data)->
		alert JSON.stringify(data)
	class MyModel extends Backbone.Model
		defaults:
			name:"N/A"
			filesize:"N/A"
			mdate:"N/A"
			synced:false
	class WallView extends Backbone.Marionette.ItemView
		className:'animated fadeInRight'
		initialize:(options)->
			@isCollection= @collection?
			if not @isCollection
				@listenTo @model,'remove',@remove
				@listenTo @model,'change',@updateFields
			else if @isCollection
				@content_model= options.content_model
				@listenTo @content_model,'remove',@remove
				@listenTo @content_model,'change',@updateFields
			@placeName = options.placeName||"default"
			@place_id = options.place_id
			c.socketio.on "#{@placeName}:message",listenSocket
		updateFields:->
			if @isCollection
				@$el.empty()
			@displayFile()
		render:->
			if @model and not @model.get("backend_synced")
				@$el.html("<p> Loading... </p>")
			else
				@displayFile()
			@
		displayFile:()->
			# @$el.html @template
			if @isCollection
				@view = new CollectionView({collection:@collection,place_id:@place_id})
				@view.render()
				@$el.html @view.$el
			else if not @isCollection and @model.get('data')?
				if @model.get('downloaded')
					View= vg(@model.get('data.mime_type'))
					@view = new View {model:@model,place_id:@place_id,type:"wall"}
				else
					@view = new DownloadView {model:@model}
				@view.render()
				@$el.html @view.$el
			else 
				console.log "error while creating the view (content data missing)"
				@$el.html "Error while loading content"
				#@$el.find('.filecontent').append(pl.getHtml(c.urlHelper.buildStaticUrl('upload/'+@placeName+"/"+@model.get('data.name'))))
		onDownload:->
			window.open "data:application/octet-stream,"+c.urlHelper.buildStaticUrl("upload/"+@placeName+"/"+@model.get('data.name'))
		remove:->
			c.socketio.removeListener "#{@placeName}:message",listenSocket
			@$el.remove()
			@view.close() if @view?
			@stopListening()
			@
		formatDate:(date)->
			console.log date.getDay()
			fdate= date.getDay()+'/'+(date.getMonth()+1)+'/'+date.getFullYear()+' '+date.getHours()+':'+date.getMinutes()+':'+date.getSeconds()
	return WallView