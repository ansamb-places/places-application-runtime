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
	"text!services/placesService/templates/activityFeed.tmpl",
	"cs!entities/Contents",
	"cs!../entities/Ansambers",
	"cs!modules/interactions/dragAndDropSupport",
	"cs!services/placesService/views/layouts/ContentLayout",
	"cs!services/placesService/views/NewContentView",
	"text!../templates/emptyActivityFeed.tmpl"
	]
,(tmpl,ContentEntities,AnsambersEntity,DragAndDrop,ContentLayout,NewContentView,emptyTmpl)->
	###private methods###
	proxyEvent= (sourceObject,parentObject,events)->
		if not _.isArray(events)
			events = [events]
		for event in events
			sourceObject.on event,->
				args = Array::slice.call(arguments)
				args.unshift(event)
				parentObject.trigger.apply parentObject,args

	View = Backbone.Marionette.View.extend

		events: 
			"click .post" : 'newPost'
			"click .cancel" : 'hideExpandedComposer'

		newPost: ->
			data = @newContentView.getApplicationContent()
			@trigger 'content:new', data.application, data.data
			@.hideExpandedComposer()
			@newContentView.deleteApplicationData()

		hideExpandedComposer: ->
			$(".p-post-dragndrop-container").hide(100)


		className: 'activityFeed'
		initialize:(options)->
			@ansambers = options.ansambers
			@owner= options.owner
			@listenTo @ansambers,'add',@updateMembers
			@listenTo @ansambers,'change',@updateMembers
			@listenTo @ansambers,'remove',@updateMembers
			@newContentView = new NewContentView
			@collection = new ContentEntities.collection
			@listenTo @collection,'add',@onNewContent
			@listenTo @collection,'reset',@collectionReset
			@listenTo @collection,'download:end',@downloadEnd
			@place_id = options.currentPlace||'default'
			@currentPlaceName = options.placeName
			@views = [] #to keep track of all subviews and delete them on collection reset
			@downloadListeners = {}

		render:->
			newContentView = @newContentView
			_tmpl = _.template(tmpl,{owner:@owner})
			@$el.empty()
			@$el.html _tmpl
			# proxyEvent(newContentView,@,'content:new')
			@$el.find("#p-place-detail-view-composer").append(newContentView.render().$el)
			@collection.each (model)=>
				@createView model
			
			newContentView.on "view:expand",->
				$(".p-post-dragndrop-container").show(100)
			# newContentView.on "view:reduce",->
			# 	$(".p-post-dragndrop-container").hide()

			$('.p-place-name').text(@currentPlaceName)
			@trigger "view:render"
			@
		setPlaceName:(placeName)->
			@collection.setPlaceName placeName
			@collection.reset()
			@$el.find("#wall-container").empty()
			@collection.fetch().done =>
				if @collection.length==0
					@$el.find("#wall-container").append(emptyTmpl)

		#data is optional and only used when a content is created by drag&drop
		onNewContent:(model)->
			if @collection.length==1
				@$el.find("#wall-container").empty()
			@createView model
		createView:(content_model)->
			created = $.Deferred()
			cl = new ContentLayout({model:content_model})
			cl.render()
			@$el.find('#wall-container').prepend(cl.$el)
			content_model.once "remove",->
				cl.remove()
			content_type = content_model.get('content_type')
			if content_type == "collection"
				content_type = content_model.get("data.app_children_type")
			@trigger 'request:view',content_type,(View)=>
				if content_model.get('content_type') == "collection"
					children = _.filter content_model.get('children'),(item)->item.content_type==content_type
					collection = new Backbone.Collection(children,{model:ContentEntities.model})
					content_model.on 'change',()->
						children = _.filter content_model.get('children'),(item)->item.content_type==content_type
						collection.reset(children)
					@setDonwnloadListener collection,true
					v = new View({content_model:content_model,collection:collection,placeName:@currentPlaceName,place_id:@currentPlace})
				else
					@setDonwnloadListener content_model,false
					v = new View({model:content_model,placeName:@currentPlaceName,place_id:@place_id})
				cl.content.show v
				@views.push(v)
				created.resolve(v)
			return created.promise()
		setDonwnloadListener:(object,isCollection)->
			if isCollection
				object.each (model)=>@setDonwnloadListener model,false
			else
				@downloadListeners[object.get('id')] = object
		downloadEnd:(content_id)->
			if _.has @downloadListeners,content_id
				@downloadListeners[content_id].set 'downloaded',true
		collectionReset:->
			v.remove() for v in @views
			@views = []

		close:->
			@trigger "view:close"
			for v in @views
				if v.close
					v.close()
				else
					v.remove()
			@newContentView.close()
			@unbind()
			Backbone.Marionette.View::close.call @
	return View
