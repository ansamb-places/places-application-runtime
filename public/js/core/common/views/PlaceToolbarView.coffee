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
	'cs!app'
	'text!../templates/placeToolbar.tmpl'
	'cs!common/menus/placeMenu'
	'cs!common/menus/settingsMenu'
	'cs!common/menus/defaultMenu'
	'cs!common/menus/addContactMenu'
	'moment'
	],(App,tmpl,placeMenu,settingsMenu,defaultMenu,addContactMenu,moment)->
	class PlaceToolbar extends Backbone.Marionette.ItemView
		template:()->
			return tmpl
		tagName: 'div'
		className:'row collapse'
		menuId : null
		menuItem : null
		menuContainer : null
		$dropDownMenu:null
		disable : false
		renaming: false
		templates:
			place: placeMenu
			settings: settingsMenu
			add_contact: addContactMenu
			default:defaultMenu

		#store callback for action_buttons
		action_button_list:{}

		#global variables
		tracked_place_id : null
		place_rename_handler : null
		initialize:->
			App.vent.on 'placeToolbar:update:title',(title,options)=>
				@ui.title.text(title)
			App.vent.on 'placeToolbar:change',(key,options,action)=>
				template= @templates[key](options)
				if not _.isUndefined template
					if (@menuId == template.id)
						if @menuItem != options.item_id
							@menuItem = options.item_id
							@menuContainer and @menuContainer.find("dd").removeClass("active")
							@menuContainer and @menuContainer.find("dd[data-id='#{options.item_id}']").addClass('active')
						return
					@tracked_place_id = options.place_id
					@menuId= template.id
					@setTitle(template.title,options)
					@setMenu(template.menu,options)
				if not _.isUndefined action
					if action.title_change
						@place_rename_handler = action.title_change
					else
						@place_rename_handler=null
				else
					@place_rename_handler=null
				@hideActionButtons()
				@disable = false

			App.vent.on 'placeToolbar:disable',(value)=>
				@disable = !!value
				stopDropDowning = (e)=>
					e.stopPropagation() if @disable
				if @disable
					$('dd>a').click stopDropDowning
				else
					$('dd>a').off 'click', stopDropDowning
			App.vent.on 'placeToolbar:changeActions',@build_action_buttons
			App.vent.on 'placeToolbar:showActions',@showActionButtons
			App.vent.on 'placeToolbar:hideActions',@hideActionButtons
		ui:
			owner:"#p-toolbar-owner"
			date:"#p-toolbar-date"
			title:"#p-toolbar-title"
			date:"#p-toolbar-date"
			sync_date:"#p-toolbar-sync-date"
			toolbar_title_container:"#p-toolbar-title-container"
			toolbar_dropdown_container:".p-toolbar-custom-dropdown"
			toolbar_action_buttons:".p-toolbar-action-buttons"
		events:
			'click .custom-dropdown':'dropDownClick'
			'dblclick #p-toolbar-title':'rename_on_dblclick'
			'click .p-toolbar-action-button':'trigger_action_button'
		menu_dismiss:(e)=>
			return if @$dropDownMenu == null
			if not $.contains(@$dropDownMenu,$(e.target))
				@ui.toolbar_dropdown_container.removeClass('open')
		dropDownClick:(e)->
			e.stopPropagation()
			if @ui.toolbar_dropdown_container.is('.open')
				@menu_dismiss(e)
			else @ui.toolbar_dropdown_container.addClass('open')
			if @ui.toolbar_dropdown_container.is('.open')
				$(document).one 'click',@menu_dismiss
			else
				$(document).off 'click',@menu_dismiss
		cleanToolBar:()->
			@ui.owner.empty()
			@ui.date.empty()
			@ui.title.empty()
			@ui.date.empty()
			@ui.sync_date.empty()
			@ui.toolbar_action_buttons.empty()
		setTitle: (title,options) ->
			@cleanToolBar()
			@ui.title.html(title)
			if options?
				if options.owner == null
					@ui.owner.text("me")
				else if options.owner?
					if options.owner.lastname[0] ## Dirty fix for missing owner
						@ui.owner.text(options.owner.firstname+" "+options.owner.lastname[0].toUpperCase())
					else @ui.owner.text(options.owner.firstname+" ")
			if options?.date?
				@ui.date.text(moment(options.date).format("MM/DD/YY"))
			if options?.sync_date?
				@ui.sync_date.text(' last sync ('+moment(options.sync_date).format("MM/DD/YY HH:mm")+')')
		setMenu: (menuData,options) ->
			@menuItem = options.item_id
			@menuContainer = $("#p-sub-nav").empty()
			_.each menuData, (item,index) =>
				active= if options.item_id==item.item_id then 'active' else ''
				item = _.extend {type:'href',href:''},item
				if item.type == 'href' and item.href 
					result = $("<dd class='#{active}' data-id='#{item.item_id}'><a href='#{item.href}'>#{item.name}</a></dd>")
				else if item.type == 'cbButton' and options.cb and options.cb[item.item_id]
					result = $("<dd><a>#{item.name}</a></dd>")
					result.find('a').click ()=>
						return if @disable
						options.cb[item.item_id].apply arguments
				else if item.type == 'dropDownView' and options.views and options.views[item.item_id]
					id= +new Date
					result = $("<dd><a data-dropdown='toolbar_dropdown_#{id}' data-options='align:custom;correct_left:225;'>#{item.name}</a></dd>")
					viewContainer= $("<div id='toolbar_dropdown_#{id}' data-dropdown-content class='f-dropdown p-toolbar-dropdown'></div>")
					viewContainer.appendTo(@menuContainer)
					view= options.views[item.item_id]
					view.$toolbarMenuEl= result
					viewContainer.html(view.$el)
				else result = $("<dd><a>#{item.name}</a></dd>")
				result.appendTo(@menuContainer)
				if item.type == 'dropDownView'
					view.render() 

			#create actions_button if it's defined
			@build_action_buttons(options.action_buttons) if options?.action_buttons

			#toolbar context menu dropdown management
			$caret = @ui.toolbar_title_container.find(".custom-dropdown")
			#$caret.off('click')
			$container = @ui.toolbar_dropdown_container
			$container.empty()
			if options.context_menu
				$caret.addClass('active')
				#generate dropdown menu
				@$dropDownMenu = $("<ul/>")
				_.each options.context_menu,(element)=>
					return if not element.text or not element.cb
					$li = $("<li>#{element.text}</li>")
					modifier=
						setText:(text)->
							$li.text(text)
						setSyncDate:(date)=>
							if date?
								@ui.sync_date.text(' last sync ('+moment(date).format("MM/DD/YY HH:mm")+')')
							else 
								@ui.sync_date.empty()
						hideItem:()->
							$li.hide()
						showItem:()->
							$li.show()
					element.init and element.init(modifier) 
					$li.appendTo(@$dropDownMenu).on 'click',(e)=>
						e.stopPropagation()
						$(document).off 'click',@menu_dismiss
						$container.removeClass('open')
						element.cb(modifier)
				@$dropDownMenu.appendTo($container)
			else
				$caret.removeClass('active')

		#global action handlers
		rename_on_dblclick:(e)->
			return if @disable
			e.preventDefault()
			return if @tracked_place_id==null or @place_rename_handler==null
			if not @renaming
				@renaming= true
				toolbar_title = $(e.currentTarget).find('#p-toolbar-title')
				old_title= @ui.title.text()
				@ui.title.html("
					<span id='new_name_container' style='width:90%'>
						<input id='new_name' style='max-width:100%;' maxlength=50 type=text/> 
					</span>
					")
				new_name = @ui.title.find('#new_name')
				new_name.val(old_title)
				new_name.autosizeInput()
				new_name.focus()
				handler=(e)=>
					container = $("#new_name_container")
					if !container.is(e.target) && container.has(e.target).length == 0
						$(document).off 'click', handler
						@ui.title.text(old_title)
						@renaming = false
				force_redraw=($el)->
					#TODO Search why width is not considered without resetting it after validate rename
					$el.width("")
					setTimeout ()->
						$el.width("100%")
					,0
				$(document).on('click', handler)

				new_name.off('keyup').on 'keyup',(e) =>
					if e.keyCode == 13
						new_title = new_name.val()
						@renaming = false
						@ui.title.text(new_title)
						if old_title != new_title
							@place_rename_handler old_title,new_title,@tracked_place_id,->
								@ui.title.text(old_title)
						@renaming = false
						$(document).off 'click', handler
						force_redraw(@ui.title)
					if e.keyCode == 27
						@ui.title.text(old_title)
						@renaming = false
		trigger_action_button:(e)->
			target = $(e.currentTarget)
			@action_button_list[target.attr("title")]() if _.isFunction(@action_button_list[target.attr("title")])
		build_action_buttons:(buttons)=>
			## build Menu managed by Active View ##
			### expected buttons = [
				{
					title:"title"
					ui_icon:
					cb:
				},
				{
				} ...]
			###
			@ui.toolbar_action_buttons.empty()
			return if !buttons or buttons.length<1
			_.each buttons,(button)=>
				if button.title and button.ui_icon and button.cb
					element = $("<div class='p-toolbar-action-button' title='#{button.title}'>#{button.ui_icon}</div>")
					@ui.toolbar_action_buttons.append(element)
					@action_button_list[button.title]=button.cb
		showActionButtons:()=>
			@ui.toolbar_action_buttons.show()
		hideActionButtons:()=>
			@ui.toolbar_action_buttons.hide()
	App.placeToolBar.show new PlaceToolbar()
