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
	'cs!./SelectableListView/ListView'
	'cs!./ViewGetter',
	'moment'
],(ListView,ViewGetter,moment)->
	class FullScreenView extends ListView
		className: 'p-single-content-page p-full-page ui-droppable'
		header:[
			{text:'',class:"small-size"}
			{text:'name',class:"sorters",sorter:'data.name'}
			{text:'by',class:"sorters large-size",sorter:'owner'}
			{text:'modified',class:"sorters large-size" ,sorter:'data.mdate'}
			{text:'size',class:"sorters large-size",sorter:'data.filesize'}
		]
		multiselectMenu:[
			{title:'all',cmd:'all'}
			{title:'none',cmd:'none'}
			{title:'read',cmd:'read'}
			{title:'unread',cmd:'unread'}
		]
		tableClassName:"p-file-table"
		getItemView:(item)->
			return ViewGetter(item.get('data').mime_type)
		isEmpty:(item)->
			(@collection.superset().isFetched() == true) and (@collection.length==0)
		initialize:(options)->
			super(options)
			@dragAndDrop=true
			@collection.superset().comparator = (model)->
				return model.get('date')
			@ansambers = options.ansambers
			@listenTo @ansambers,'add',@updateMembers
			@listenTo @ansambers,'change',@updateMembers
			@listenTo @ansambers,'remove',@updateMembers

			@listenTo @,'multiselect:item:removed',@onItemUnSelected
			@listenTo @,'multiselect:item:added',@onItemSelected
			@listenTo @,'multiselect:items:removed',@onItemsUnSelected
			@listenTo @,'multiselect:items:added',@onItemsSelected

			@listenTo @,'dropdown:all:click',=>@toggleGlobalSelect(true)
			@listenTo @,'dropdown:none:click',=>@toggleGlobalSelect(false)
			@listenTo @,'dropdown:read:click',=>@selectWithFilter({'read':true})
			@listenTo @,'dropdown:unread:click',=>@selectWithFilter({'read':false})

			@type = options.viewType
			@place= options.place
			@owner = options.owner

		onRender:=>
			if @collection.superset().isFetched() == false
				@showOverlay true,'<span data-icon="l" class="p-loading p-color-place p-big"></span>'
				@collection.superset().onAfterFetch =>
					@checkEmpty()
					@showOverlay false
			unless @place.isReady()
				setTimeout ()=>
					@$el.html 'Welcome to <strong>' + @place.get('name') + '</strong>. The activation of the place is in progress. Your encryption keys have to be certified by the owner of the place.'
					@place.once "change:network_synced",@render
				, 0
		itemViewOptions:(model, index)->
			return {
				model:model
				place:@place
				type:@type
				tagName:@itemTagName
				checkboxClass:@itemViewCheckboxClass
				selectedPropertyName:@selectedPropertyName
			}
		onAfterItemAdded:(itemView)->
			return if itemView.model.get('content_type')=='file:stream'
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
			sortField = $(e.currentTarget).data('sorter')
			if target.hasClass('asc')
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('dsc')
			else 
				@$el.find('.sorters').removeClass('asc dsc')
				target.addClass('asc')
			@collection.superset().comparator= (model,model2)->
				m1 = model.get(sortField) || ""
				m2 = model2.get(sortField) || ""
				if sortField == 'data.mdate'
					m1 = moment(m1).format('X')
					m2 = moment(m2).format('X')
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
			selected = _.filter @getSelectedItems(),(item)->
				# ignore files which are not downloadable for now (like file:stream)
				return item.get('downloadable')
			return selected
		buildDDHelper:(model)->
			isModelSelected = @isModelSelected(model)
			if not isModelSelected
				helper= $( "<div class='p-dropHover'>"+model.get("data.name")+"</div>" )
			else
				helper=""
				_.each @getSelectedFiles(),(item)->
					helper= helper+item.get('data').name+'<br>'
				helper= $("<div class='p-dropHover'>"+helper+"</div>")
			helper.data('type',"file")
			if not isModelSelected
				helper.data('files',[{id:model.get('id')}])
			else
				helper.data('files',_.map(@getSelectedFiles(),(item)->return item.get('id')))
			helper.data('place_id',@place.get('id'))
			return helper

		### multiple selection operations ###
		_selected_menu: [
			{title: "delete all",cmd:"delete"},
			{title: "download all", cmd:"download"}
		]
		onItemSelected:(model,view)->
			if view.contextMenuInstance
				view.contextMenuInstance.change_menu(@_selected_menu)
				view.contextMenuInstance.change_trigger_el(@)

		onItemUnSelected:(model,view)->
			view.contextMenuInstance.reset() if view.contextMenuInstance

		onItemsUnSelected:()->
			@children.forEach (view)->
				view.contextMenuInstance.reset() if view.contextMenuInstance
		onItemsSelected:()->
			@children.forEach (view)=>
				if view.contextMenuInstance
					view.contextMenuInstance.change_menu(@_selected_menu)
					view.contextMenuInstance.change_trigger_el(@)


