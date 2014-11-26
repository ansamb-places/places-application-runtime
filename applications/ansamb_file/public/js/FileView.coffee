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
	'text!../template/list.tmpl',
	'text!../template/thumb.tmpl',
	'text!../template/list_no_synced.tmpl',
	'text!../template/thumb_no_synced.tmpl',
	'moment'
	],(c,ltmpl,ttmpl,ltmpl_no_synced,ttmpl_no_synced,moment)->
	class FileView extends Backbone.Marionette.ItemView
		contextMenu: [
			{title: "open", cmd: "open"},
			{title: "open in finder", cmd: "open_folder"},
			{title: "rename", cmd: "rename"},
			{title: "delete",cmd:"delete"},
			{title: "download", cmd:"download"}
		]
		initialize:(options)->
			@listenTo @model,'change',@render
			@listenTo @,"preview",@preview
			@context= c
			@isCollection= options.isCollection
			@place=options.place
			@place_id = options.place.get('id')
			@checkboxClass = options.checkboxClass
			@selectedPropertyName = options.selectedPropertyName
			@hide= options.hide
			@type= options.type
			@templates=
				gallery:
					[ttmpl_no_synced,ttmpl]
				list:
					[ltmpl,ltmpl]
				wall:[ttmpl_no_synced,ttmpl]

			@nativeHtml= ['video/ogv','video/mp4','video/webm','audio/wav','audio/ogg']
			@key_rename_accept = 13
			@key_rename_cancel = 27
			@dblclick = false
			@date = +new Date()

			@listenTo @,"contextmenu:delete",@delete
			@listenTo @,"contextmenu:rename",@rename
			@listenTo @,"contextmenu:open",=>
				@callPreview()
			@listenTo @,"contextmenu:download",=>
				@trigger "content:download",@model
			@listenTo @,"contextmenu:open_folder",@open_folder

			if @model.get('content_type') == "file:stream"
				#disable the "select" feature for this item in this case
				@model.set('selectDisable',true,{silent:true})
				@contextMenu= [{title: "open", cmd: "open"}]
				@$el.addClass 'select-disable'

			super()
		modelSelectChange:(selected)->
			@$el.find(".#{@checkboxClass}").prop('checked',selected)
			@$el.toggleClass("p-file-selected",selected)
		callPreview:->
			@trigger "content:preview",@model
			@preview()
		preview:->
			console.log "No preview defined for this content type"
		serializeData:()->
			data= {}
			if @model
				data = this.model.format()
				if @model.get('content_type') == 'file:stream'
					data.data.url= c.urlHelper.buildUrlToStream(@place_id,data.id)
				else
					data.data.url= c.urlHelper.buildUrlToFile(@place_id,data.data.relative_path)
				data.img_type= @img_type if @img_type
				if @mode_preview
					data.preview= true
				else data.preview= false
				data.updated_date = moment(data.updated_at).format('MM/D/YY hh:mm')
				data.extension = /.+?(\.[^.]*$|$)/.exec(data.data.name)[1]
				data.place_disabled = @place.isDisabled()
			return data
		template:(model)=>
			if @templates[@type]?
				return _.template @templates[@type][+model.backend_synced],model 
			else 
				return "no template"
		onRender:->
			if @hide
				@$el.addClass('hide')
			if not @model.get('downloaded')
				@undelegateEvents()
			else
				@delegateEvents()
			@$el.find('[title]').tooltip({
				show:false,
				hide:false,
				content:()->
					$(@).prop('title')
				position:
					my: "left top", at: "left bottom"
				tooltipClass: 'p-tooltip'
			})
			if !@model.get('read')
				@$el.addClass('p-unread')
			else @$el.removeClass('p-unread')
			if @model.get('new')
				@$el.addClass('p-new')
			else @$el.removeClass('p-new')

		events:
			"click [data-action=delete]":"delete"
			"click [data-action=download]" : "download"
			"click [data-action=modify]":"modify"
			"dblclick ":"callPreview"
		delete:(e)->
			@trigger "content:delete",@model if (@model.get("downloaded") and @model.get("uploaded"))
		download:(e)->
			@trigger "content:download", @model if (@model.get("downloaded") and @model.get("uploaded"))
		open_folder:(e)->
			@trigger "content:open_folder", @model if (@model.get("downloaded") and @model.get("uploaded"))
		modify:(e)->
			console.log("modify")
		rename:(e)->
			filename= @$el.find('.filename')
			return if filename.hasClass("renaming")
			filename.html '<input class="filename" placeholder="filename" type="text" value="' + @model.get('data').name + '"/>'
			filename.toggleClass("renaming")
			textArea = filename.find("input")
			textArea.select()
			textArea.autosizeInput()
			
			cancel_rename = (e) =>
				filename.toggleClass("renaming")
				filename.html @model.get('data').name

			confirm_rename = (e) =>
				filename.toggleClass("renaming")
				if @model.get('data').name != textArea.val()
					@trigger "content:rename",@model,textArea.val()
				filename.html @model.get('data').name

			textArea.focusout cancel_rename

			textArea.keyup (e)=>
				if e.keyCode is @key_rename_accept then confirm_rename()
				if e.keyCode is @key_rename_cancel then cancel_rename()
