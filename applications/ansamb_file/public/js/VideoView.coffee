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
	'cs!./FileView',
	'text!template/videoCollection.tmpl',
	'text!template/video.tmpl',
	'cs!js/pluginLoader'
],(FileView,ctmpl,tmpl,pl)->
	class ItemView extends FileView
		initialize:(options)->
			super(options)
			@listenTo @,'modal:close',@close
			@mode_preview= true
			@media_id= "media_id_"+pl.getMediaNewId()
			@templates.gallery[1] = ctmpl
			@templates.wall= ["Loading",tmpl]
			@templates.popup= ["",tmpl]
			@plugin= null
			if @type== 'popup' and not navigator.plugins["Shockwave Flash"] and @nativeHtml.indexOf(@model.get('data.mime_type'))==-1
				@templates.popup[1]= "Please download FlashPlayer if you want to read this file"
		serializeData:()->
			data= super()
			data.media_id= @media_id
			return data
		preview:(e)->
			e.preventDefault() if e
			options= @options
			options.hide= false
			options.tagName= 'div'
			options.popup= true
			options.type= 'popup'
			@context.createPopup new ItemView options
		onRender:()->
			super()
			if @type == 'popup'
				force= false
				force = true if @model.get('data.mime_type') == 'video/mp4'
				###setTimeout ()=>
					plugin= pl.initMedia(@media_id,force)
				,1###
		onClose:()->
			if @plugin
				@plugin.pause()
				@plugin.remove()
