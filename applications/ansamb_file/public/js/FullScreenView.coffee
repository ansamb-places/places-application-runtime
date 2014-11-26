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
	'cs!./ViewGetter',
	'text!../template/fullScreen.tmpl'
	'cs!./FileView'
	'moment'
],(ViewGetter,tmpl,FileView,moment)->
	class emptyView extends Backbone.Marionette.ItemView
		template:->
			return '<td> </td> <td>There is no file in this Place</td>'
	class FullScreenView extends Backbone.Marionette.CompositeView
		tagName: 'div'
		itemViewContainer: '.p-gallery'
		className: 'p-single-content-page p-full-page ui-droppable'
		itemTagName: 'li'
		emptyView: emptyView
		template:()=>
			return _.template tmpl,{type: @type, owner: @place.get('owner')}
		getItemView:(item)->
			return ViewGetter(item.get('data').mime_type)
			#return FileView
		isEmpty:(item)->
			(@collection.superset().isFetched() == true) and (@collection.length==0)
		initialize:(options)->
			@dragAndDrop=true
			@collection.superset().comparator = (model)->
				return model.get('date')
			@ansambers = options.ansambers
			@listenTo @ansambers,'add',@updateMembers
			@listenTo @ansambers,'change',@updateMembers
			@listenTo @ansambers,'remove',@updateMembers
			@listenTo @,'itemview:file:select',@fileSelect
			@type = options.viewType
			@place= options.place
			@owner = options.owner
			if @type == 'list'
				@itemViewContainer= 'tbody'
				@itemTagName= 'tr'

		onRender:=>
			if @collection.superset().isFetched() == false
				@showOverlay true,'<span data-icon="l" class="p-loading p-color-place p-big"></span>'
				@collection.superset().onAfterFetch =>
					@checkEmpty()
					@showOverlay false
			unless @place.isReady()
				@place.once "change:network_synced",@render
				setTimeout ()=>
					@$el.html 'Welcome to <strong>' + @place.get('name') + '</strong>. The activation of the place is in progress. Your encryption keys have to be certified by the owner of the place.'
				, 0
		itemViewOptions:(model, index)->
			return {model:model,place:@place,type:@type,tagName:@itemTagName}
		onAfterItemAdded:(itemView)->
			itemView.$el.draggable
				helper: ( event ) =>
					return @buildDDHelper(itemView.model)
				zIndex:999
				appendTo:'body'
				cursor: 'move'
				cursorAt:
					top:5
					left:5
				scope:'places-draggable'
				containment:"parent"
		events:
			"click .sorters":"sortBy"
		sortBy:(e)=>
			e.preventDefault()
			target = $(e.currentTarget)
			sortField = $(e.currentTarget).data('action')
			if target.hasClass('asc')
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('dsc')
			else 
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('asc')
			@collection.superset().comparator= (model,model2)->
				m1 = model.get(sortField) || ""
				if target == 'data.date'
					m1 = moment(m1)
				m2 = model2.get(sortField) || ""
				if typeof m1 == "string"
					m1= m1.toLowerCase()
				if typeof m2 == "string"
					m2= m2.toLowerCase()
				return 0 if m1 == m2
				if target.hasClass 'dsc'
					return 1 if m1 < m2
					return -1 if m1 > m2
				else
					return 1 if m1 > m2
					return -1 if m1 < m2
			@collection.superset().sort()
	
		showOverlay:(show,message)=>
			overlay = @$el.find('.loadingOverlay')
			if show
				if not _.isUndefined message
					overlay.find('.notif').html message
				else
					overlay.find('.notif').html 'Loading ...'
			if show then overlay.fadeIn('fast') else overlay.fadeOut('fast')
		onDeleteAction:()->
			if !@deleting
				@showOverlay true,'<span data-icon="l" class="p-loading p-color-alert p-big"></span><p>deleting the place</p>'
				@deleting= true
			else
				@showOverlay false
				@deleting= false
		getSelectedFiles:()->
			selected = @collection.where({selected:true}).map (item)->
				{id:item.get('id')}
			return selected
		buildDDHelper:(model)->
			if not model.get("selected")
				helper= $( "<div class='p-dropHover'>"+model.get("data.name")+"</div>" )
			else
				helper=""
				_.each @collection.where({selected:true}),(item)->
					helper= helper+item.get('data').name+'<br>'
				helper= $("<div class='p-dropHover'>"+helper+"</div>")
			helper.data('type',"file")
			if not model.get("selected")
				helper.data('files',[{id:model.get('id')}])
			else
				helper.data('files',@getSelectedFiles())
			helper.data('place_id',@place.get('id'))
			return helper
