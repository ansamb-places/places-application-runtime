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
	'text!./template/selectableListView.tmpl'
	'text!./template/globalCheckbox.tmpl'
],(template,gb_check_tmpl)->
	return class SelectableListView extends Backbone.Marionette.CompositeView
		header:null
		itemTagName:'tr'
		itemViewContainer:'tbody'
		globalCheckboxClass:'selectable-global-checkbox'
		itemViewCheckboxClass:'item-checkbox'
		eventPrefix:'multiselect'
		selectedPropertyName:'_multiselect_selected'
		template:=>
			### Generate the header html ###
			# we need to clone the header object because it could belongs to the view's prototype
			header_items = if _.isArray(@header) then _.clone(@header) else []
			# automatically generate the global checkbox item
			if header_items.length > 0
				checkbox = _.template gb_check_tmpl,{globalCheckboxClass:@globalCheckboxClass}
				header_items.unshift {text:checkbox,class:'small-size'}
			header_html = _.map(header_items,(item)->
				className = item.class ? ""
				sorter = item.sorter ? ""	
				text = if _.isString(item) then item else item.text
				return "<th class='#{className}' data-sorter='#{sorter}'>#{text}</th>"
			).join('')
			tableClassName = @tableClassName ? ""
			return _.template template,{
				header_html:header_html
				tableClassName:tableClassName
			}
		constructor:->
			Backbone.Marionette.CompositeView::constructor.apply @,arguments
			@selected_size = 0
			@dropdownClass = "multiselect-dropdown-menu-#{+new Date}"
			@isEmpty = (collection)=>
				$empty_message = @$el.find(".empty_message")
				$table = @$el.find(".#{@tableClassName}")
				if collection.length == 0
					$empty_message.removeClass("hide")
					$table.addClass("hide")
				else
					$empty_message.addClass("hide")
					$table.removeClass("hide")
				return false
		initialize:(options)->
			@listenTo @,'itemview:render',@createSelectHandler
			@listenTo @,'render',@afterRender
			@listenTo @collection,"change:#{@selectedPropertyName}",@modelChange
			@listenTo @collection,"add",@updateGlobalEvent
			@listenTo @collection,"remove",@updateGlobalEvent
		afterRender:->
			@$el.find(".#{@globalCheckboxClass}").off('click').on 'click',(e)=>
				selected = !!$(e.currentTarget).prop('checked')
				@changeGlobalSelect(selected)
				return true
			@generateMenu @multiselectMenu if @multiselectMenu?
			@updateGlobalEvent()
		changeGlobalSelect:(selected)->
			old_selected_items = _.map @getSelectedItems(),(model)->model
			@collection.forEach (model)=>
				return if not @isModelSelectable(model)
				model.set @selectedPropertyName,selected,{silent:true}
				if model.changedAttributes(@selectedPropertyName)
					@modelChange model,{no_event:true}
			if selected == true and (items = @getSelectedItems()).length>0
				@trigger "#{@eventPrefix}:items:added",items
			else
				@trigger "#{@eventPrefix}:items:removed",old_selected_items
			@updateGlobalEvent()
		toggleGlobalSelect:(_selected)->
			selected = !!@$el.find(".#{@globalCheckboxClass}").prop('checked')
			if _.isUndefined(_selected)
				selected = !selected
			else
				selected = _selected
			@changeGlobalSelect selected
		isModelSelectable:(model)->
			return !(model and model.get('selectDisable') == true)
		selectWithFilter:(filter)->
			boolToInt=(value)->
				if typeof value == "boolean"
					if value
						value= 1
					else value= 0 
				return value
			@collection.forEach (model)=>
				return if not @isModelSelectable(model)
				if boolToInt(model.get(_.keys(filter)[0]))==boolToInt(_.values(filter)[0])
					model.set @selectedPropertyName,true,{silent:true}
				else
					model.set @selectedPropertyName,false,{silent:true}
				if model.changedAttributes(@selectedPropertyName)
					@modelChange(model,{no_event:false})

		createSelectHandler:(view)->
			# update the view if a render have been done after a reset event for example
			view.modelSelectChange !!view.model.get(@selectedPropertyName) if view?.modelSelectChange
			view.$el.find(".#{@itemViewCheckboxClass}").off('click').on 'click',(e)=>
				return false if not @isModelSelectable(view.model)
				@itemSelectedChange(e,view)
		itemSelectedChange:(e,view)=>
			selected = !!$(e.currentTarget).prop('checked')
			model = view.model
			# we changed the model silently to not triggered a view render
			model.set(@selectedPropertyName,selected,{silent:true})
			@modelChange model
		modelChange:(model,options)->
			options ?= {}
			selected = model.get(@selectedPropertyName)
			view = @children.findByModel(model)
			view.modelSelectChange selected
			if options.no_event != true
				if selected == true
					@trigger "#{@eventPrefix}:item:added",model,view
				else
					@trigger "#{@eventPrefix}:item:removed",model,view
				@updateGlobalEvent()
		updateGlobalEvent:(options)->
			options ?= {}
			previous_length = @selected_size
			new_length = @getSelectedItems().length
			selectable_size = @collection.filter(@isModelSelectable).length
			# emit a special events only once when a multi-select occured
			if new_length > 0 and previous_length == 0
				@trigger "#{@eventPrefix}:enable"
			else if new_length == 0 and previous_length != 0
				@trigger "#{@eventPrefix}:disable"
			@selected_size = new_length
			#update global checkbox state
			if options.update_checkbox != false
				checked = (selectable_size > 0 and @getSelectedItems().length == selectable_size)
				@$el.find(".#{@globalCheckboxClass}").prop('checked',checked)
			@$el.find(".#{@globalCheckboxClass}").toggleClass('select-disable',!(selectable_size>0))
		createSelectedFilter:(selected)->
			filter = {}
			filter[@selectedPropertyName] = selected
			return filter
		getSelectedItems:->
			return @collection.where @createSelectedFilter(true)
		isModelSelected:(model)->
			return model.get(@selectedPropertyName) == true
		### dropdown menu management ###
		generateMenu:(items)->
			li_template = _.template("<li><%= title %></li>")
			$carret = @$el.find(".#{@globalCheckboxClass}").next()
			$parent = @$el.find(".#{@globalCheckboxClass}").parent()
			$container = @$el.find(".dropdown")
			$ul = $("<ul class='#{@dropdownClass}'/>")
			_.each items,(item)=>
				$item = $(li_template(item))
				$item.off('click').on 'click',(e)=>
					e.preventDefault()
					$parent.toggleClass('active')
					@trigger "dropdown:#{item.cmd}:click"
				$ul.append $item
			# update DOM
			$carret.off('click').on 'click',(e)->
				e.stopPropagation()
				$parent.toggleClass("active")
			$container.html($ul)
			$(document).off('click',@dropdown_dismiss).on 'click',@dropdown_dismiss
		dropdown_dismiss:(e)=>
			$ul = $(".#{@dropdownClass}")
			$parent = @$el.find(".#{@globalCheckboxClass}").parent()
			if not $.contains($ul,$(e.target))
				$parent.removeClass('active')
