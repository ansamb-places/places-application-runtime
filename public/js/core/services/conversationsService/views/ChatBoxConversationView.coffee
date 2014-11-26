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
	'cs!entities/Contents'
	'cs!modules/ApplicationManager'
	'cs!modules/ViewLoader'
	'cs!modules/interactions/JqueryUIDragAndDropManager'
	'cs!backend_api/PlaceBackendAPI'
	'cs!backend_api/ApplicationBackendAPI'
	'text!../templates/Conversation.tmpl'
	'text!../templates/FullScreenConversation.tmpl'
	'cs!entities/Contents'
	'cs!../views/ContentProxyView'
],( Contents, ApplicationManager, ViewLoader,
	JqueryUIDragAndDropManager, PlaceBackendAPI, AppBackendAPI,
	ChatBoxTmpl, FullScreenTmpl,ContentEntities, ContentProxyView)->
	return class View extends Backbone.Marionette.CompositeView
		tagName: 'div'
		className: 'conversation-div-inner magictime magic vanishIn'
		itemViewContainer: '.discussion'
		itemView:ContentProxyView
		template:=>
			switch @mode
				when 'chatbox'
					return _.template ChatBoxTmpl,{placeName: @place_name, ansambers: @ansambers}
				when 'full-screen'
					@$el.addClass('fullScreen')
					return _.template FullScreenTmpl,{placeName: @place_name}
				else
					return _.template ChatBoxTmpl,{placeName: @place_name}
		initialize:(options)->
			@place= options.place
			@place_name = @place.get('id') ## TODO modify all used variable
			@place_id= @place.get('id')
			@ansambers = options.ansambers||[]
			@ansambers_colors = {}
			@mode = options.mode || 'chatbox'
			@collection = new Contents.collection
			@collection.setPlaceName(@place_name)
			@collection.fetch()
			@view_for_content_type = {}
			@isMultiple = @ansambers.length>1
			@stacked=false
			@isAutoScroll=true
			@listenTo @place,"change:status",@disable
			super options
		itemAdd:(model)->
			if @stacked
				@trigger "view:display",@
		_getConcreteItemView:(item)->
			getView = $.Deferred()
			content_type = item.get('content_type')
			if _.isUndefined(@view_for_content_type[content_type])
				ApplicationManager.get().then (instance)=>
					app = instance.getApplicationForType content_type
					ViewLoader.getView app,'conversation',(view)=>
						@view_for_content_type[content_type] = view
						getView.resolve view
						@autoScroll() #have to scroll here to avoid diff height between proxyItemView and ConreteItemView
			else
				getView.resolve @view_for_content_type[content_type]
			return getView.promise()
		itemViewOptions:(model, index)->
			color_class = " "
			if model.get('owner') != null
				if @ansambers_colors[model.get 'owner'] == undefined
					@ansambers_colors[model.get 'owner'] = 'p-message-'+((Object.keys(@ansambers_colors).length+1)%5)
				color_class = @ansambers_colors[model.get 'owner']

			return {place_id:@place_id,content_view_promise:@_getConcreteItemView(model),color:color_class}
		onAfterItemAdded:(item)->
			if @isAutoScroll
				@autoScroll() 
			@boxBlink() if item.model.get('owner')?
		addInformation:(text)->
			info = $("<div class='info'><span class='entypo'>&#59141;</span>#{text}</div>")
			@$itemViewContainer.append info
			if @isAutoScroll
				@autoScroll()
		autoScroll:->
			return if !@$itemViewContainer
			$conversationbox = @$itemViewContainer
			$conversationbox.scrollTop($conversationbox.prop('scrollHeight'))
		onRender:->
			@$el.find('#new_post').autosize()
			el = @$el.find(".conversation-div")
			el.droppable
				scope:'places-draggable'
				hoverClass:"p-dropOverlay"
				tolerance:"intersect"
				drop:(event,ui)=>
					type = ui.helper.data('type')
					@showOverlay(false)
					el.removeClass("p-dropOverlay")
					switch type
						when 'ansamber'
							uid = ui.helper.data('uid')
							@trigger "ansamber:uid",uid,(ansamber)=>
								if !_.findWhere(@ansambers,{uid:uid})
									@addAnsamber ansamber.toJSON()
						when 'file'
							place_id = ui.helper.data('place_id')
							files = ui.helper.data('files')
							_.each files,(file)=>
								@trigger "file:copy",file.id,place_id,(file)=>
									@addFile file
				over:(event,ui)=>
					type = ui.helper.data('type')
					if type == 'ansamber'
						uid = ui.helper.data('uid')
						if _.findWhere(@ansambers,{uid:uid})
							@showOverlay(true,"This contact is already in the conversation")
						else
							el.addClass("p-dropOverlay")
							ui.helper.showAddIcon(true)
					else # type is 'file'
						el.addClass "p-dropOverlay p-file-overlay"
				out:(event,ui)=>
					@showOverlay(false)
					if ui.helper.data('type') == "ansamber"
						ui.helper.showAddIcon(false)
					el.removeClass("p-dropOverlay p-file-overlay")

			@$el.find('.ansambers').tooltip({
				show:false,
				hide:false,
				items: ".ansambers"
				content:()->
					return $(@).html().replace(/,/gi,"<br>")
				position:
					my: "center bottom", at: "center top"
				tooltipClass: 'p-tooltip'
			})
			JqueryUIDragAndDropManager.registerNewDroppable(@$el.find(".conversation-div"), 10)
			@$el.find(".discussion").off("scroll").on("scroll",(e)=> @onScroll(e))
			@disable() if @place.get('status') == 'disabled'
			@ansamber_status_change()
		ansamber_status_change:=>
			# if @ansambers.length == 1
			# 	if @ansambers[0].status != "online"
			# 		@ui.audio_icon.addClass 'disable'
			# 		@ui.video_icon.addClass 'disable'
			# 	else
			# 		@ui.audio_icon.removeClass 'disable'
			# 		@ui.video_icon.removeClass 'disable'
		selectTooltip:()->
			return $("[data-selector=#{@$el.find('.ansambers').attr('data-selector')}].tooltip")
		appendAnsamberTooltip:(ansamber)->
			@selectTooltip().append "#{ansamber}<br/>"
		showOverlay:(show,message)=>
			overlay = @$el.find('.dropOverlay')
			if show
				if not _.isUndefined message
					overlay.find('.notif').html message
				else
					overlay.find('.notif').html '<span class="entypo">&#59136;</span> Drop to add the contact'
			if show then overlay.fadeIn('fast') else overlay.fadeOut('fast')
		#this function will just add an ansamber without any network operation
		_addAnsamber:(ansambers)->
			ansambers = [ansambers] if not _.isArray ansambers
			_.each ansambers,(ansamber)=>
				if !_.findWhere(@ansambers,{uid:ansamber.uid})
					@ansambers.push ansamber
					@addInformation "#{ansamber.firstname} #{ansamber.lastname} has been added to the conversation"
				else
					@addInformation "#{ansamber.firstname} #{ansamber.lastname} already belongs to the conversation"
		addAnsamber:(ansambers)->
			return if ansambers == "" or ansambers==null or _.isUndefined(ansambers)
			ansambers = [ansambers] if not _.isArray(ansambers)
			placeReady = $.Deferred()
			if @isMultiple
				placeReady.resolve()
			else
				@$el.find('.ansambers').empty()
				#we have to add the existing ansamber if the conversation was a one-to-one one
				ansambers.unshift @ansambers[0]
				@isMultiple = true
				#we need to create a new conversation
				@trigger "create:randomplace",placeReady
			placeReady.done =>
				_.each ansambers,(ansamber,key)=>
					PlaceBackendAPI.addAnsamberToPlace(ansamber.uid,@place_name).done =>
						@_addAnsamber ansamber
						if @ansambers.length<2 and key==0
							@$el.find('.ansambers').append ansamber.firstname+" "+ansamber.lastname 
						else
							@$el.find('.ansambers').append ", "+ansamber.firstname+" "+ansamber.lastname
					.fail (error)->
						alert "Error on ansamber add"
			placeReady.fail (err)->
				console.log(err)
		getAnsamberUidArray:->
			return _.map(@ansambers,(ansamber)->ansamber.uid)
		addFile:(file)->
			@isAutoScroll = true
			@collection.add(file)
		switchPlaceName:(new_place_name)->
			@addInformation "A new group conversation has been created"
			@collection.setPlaceName new_place_name
			@collection.reset(null,{silent:true})
			@collection.fetch()
			@place_name = new_place_name
			@trigger 'change:place_name',new_place_name
		#this function is triggered on addContact conversation window click
		menu_add_ansamber:->
			@trigger 'action:add_ansamber',@getAnsamberUidArray(),(added_ansambers)=>
				return if added_ansambers.length==0
				@addAnsamber added_ansambers
		call_ansamber_audio:->
			if @ansambers.length == 1
				@trigger 'audio:call', @ansambers[0]
		call_ansamber_video:->
			if @ansambers.length == 1
				@trigger 'visio:call', @ansambers[0]
		focus:->
			@ui.textbox.focus()
		stopBlinking:(e)->
			@ui.header.removeClass("has-new-content") if @isAutoScroll
		boxBlink:(e)->
			### blink chat if chatbox is not focused or not at bottom###
			if (not @ui.textbox.is(':focus') or not @isAutoScroll) and not @place.get('status')== "disabled"
				@ui.header.addClass("has-new-content")
		ui:
			textbox:'textarea'
			header:'header'
			conv_div:'.conversation-div'
			audio_icon:'.audio-contact'
			video_icon:'.visio-contact'
			add_contact:'.add-contact'
		events:
			'click':"stopBlinking"
			'click #new_post_submit':"newPost"
			'focus textarea':'stopBlinking'
			'keydown textarea':'newPost'
			'click a.close-chat':'close'
			'click .add-contact':'menu_add_ansamber'
			'click .audio-contact': 'call_ansamber_audio'
			'click .visio-contact': 'call_ansamber_video'
			'click .setFullScreen':'fullScreen'
		newPost:(e)->
			e.stopPropagation()
			return if e.keyCode != 13
			if e.keyCode == 13
				e.preventDefault() 
			value = @$el.find("#new_post").val().trim()
			if value != ""
				model_json =
					content_type:'post'
					backend_synced:false
					owner:null
					data:
						post:value
				@isAutoScroll = true
				content_model = new Contents.model(model_json) #create it and fill it later
				@collection.add(content_model)
				AppBackendAPI.newContent('ansamb_post',@place_name,{post:value})
				.done (data)->
					content_model.set(data)
					content_model.set("backend_synced",true)
			@$el.find("#new_post").val("").trigger('autosize.resize')
		postFromKernel:(content,data)->
			content = _.extend content,{backend_synced:true}
			@collection.add(content)
		onScroll:(e)->
			scroll= $(e.currentTarget)
			if scroll.scrollTop()+scroll.innerHeight() == scroll[0].scrollHeight
				@ui.header.removeClass("has-new-content") if not @isAutoScroll
				@isAutoScroll = true
			else 
				@isAutoScroll = false

		onClose:(e)->
			e.stopPropagation()
			@trigger 'view:remove'
		fullScreen:(e)->
			e.preventDefault()
			@mode = 'full-screen'
			Backbone.history.navigate "conversation/place_id/#{@place_name}",{trigger:true}
		disable:(model)->
			if @place.get('status')=='disabled'
				@ui.textbox.prop('disabled', true)
				@ui.textbox.attr("placeholder", "not your friend anymore");
				@ui.conv_div.droppable('disable')
				@ui.audio_icon.remove()
				@ui.video_icon.remove()
				@ui.add_contact.remove()
			else if @place.get('status')=='validated'
				@ui.textbox.prop('disabled', false)
				@ui.textbox.attr("placeholder", "Add A Reply");
				@ui.conv_div.droppable('enable')
