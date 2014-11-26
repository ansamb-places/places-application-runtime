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
	'cs!app',
	'cs!./ViewFactory'
],(App,ViewFactory) ->
	class ConversationManager
		#remove event define which event to listen to auto remove the view from the stack
		#switch event define which event to listen to switch a view from one place_id to another into the stack
		constructor:(options)->
			@stack = {}
			@removeEvent = options?.removeEvent || null
			@switchEvent = options?.switchEvent || null
			@chatboxSize= 260
			@stackView= null
			@$stackTag= $('.stackTag')
			$(window).resize ()=>
				@stackConversation()
		setup:(leftRegion,chatBoxes)->
			@$leftRegion= $(leftRegion)
			@$chatBoxes= $(chatBoxes)
		isConversationExists:(place_id)->
			return Object::hasOwnProperty.call(@stack,place_id)
		getConversation:(place_id)->
			return @stack[place_id]||null
		addConversation:(place_id,view)->
			return false if @isConversationExists(place_id)
			@stack[place_id] = view
			view.stacked= false
			if @removeEvent?
				view.on @removeEvent,=>
					@removeConversation place_id
			if @switchEvent?
				view.on @switchEvent,(new_place_id)=>
					@switchConversationPlace place_id,new_place_id
			view.on "view:display",(view)=>
				@selectStackedConversation(view.place_name) if view? 
			return true
		removeConversation:(place_id)->
			delete @stack[place_id]
			# dom object is not deleted yet so we have to delayed the call
			setTimeout ()=>
				@stackConversation(true)
			,0
		switchConversationPlace:(old_place_id,new_place_id)->
			view = @stack[old_place_id]
			@stack[new_place_id] = view
			delete @stack[old_place_id]
		stackConversation:(force)->
			##check if conversations have to be stacked
			if @$chatBoxes.offset().left-@$leftRegion.offset().left < 0 and not force
				_.each @stack,(item,key)=>
					if @$chatBoxes.offset().left-@chatboxSize < 0 and not item.stacked
						item.$el.addClass('stacked')
						item.stacked = true
						if not @stackView?
							#create stack view if is not existing
							@stackView = ViewFactory.buildStackChat()
							@stackView.on
								"itemview:chatbox:select":(itemview,model)=>
									@setFocusOnConversation(model.get('id'),false)
							App.stackedChatBoxes.show @stackView
						@stackView.collection.add({id:key,ansambers:item.ansambers})
						@updateStackTag()
			else if @stackView?.collection? or (force and @stackView?.collection?)
				_.each @stack,(item,key)=>
					if (@$chatBoxes.offset().left-@chatboxSize >= @$leftRegion.offset().left)
						item.$el.removeClass('stacked')
						item.stacked = false
						@stackView.collection.remove(@stackView.collection.findWhere({id:key}))
						if @stackView.collection.length == 0
							@stackView.close()
							@stackView = null
						@updateStackTag()
		selectStackedConversation:(place_id)->
			item= @stack[place_id]
			if item
				if itemToStack= _.findWhere(@stack,{stacked:false})
					itemToStack.$el.addClass('stacked')
					itemToStack.stacked = true
					if @stackView?
						@stackView.collection.add({id:itemToStack.place_name,ansambers:itemToStack.ansambers})
					@stackView.collection.remove(@stackView.collection.findWhere({id:place_id}))
					item.$el.removeClass('stacked')
					item.stacked = false
		updateStackTag:()->
			if @stackView?.collection?
				@$stackTag.html @stackView.collection.length
			else 
				@$stackTag.empty()
		setFocusOnConversation:(place_id,focus)->
			view = @stack[place_id]
			if view?
				if view.stacked
					@selectStackedConversation(place_id)
				view.focus() if focus
	return new ConversationManager({removeEvent:'view:remove',switchEvent:'change:place_name'})