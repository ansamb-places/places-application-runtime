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
	"backboneEventStandalone",
	'cs!backend_api/ApplicationBackendAPI'
]
,(BackboneEvents,AppAPI)->
	class DragAndDrop
		constructor:(options)->
			_.extend @,Backbone.Events
			@options=options
			throw new Error("DOM element not specified") if _.isUndefined(options.dom)
			file_input = $("<input type='file' style='display:none' name='file' />")

			$(options.dom[0]).on('dragover',(e)->
				options.dom.addClass("p-dropOverlay"))
			.on('dragleave',(e)->
				options.dom.removeClass("p-dropOverlay"))
			.on('drop',(e)=>
				e.preventDefault()
				e= e.originalEvent
				options.dom.removeClass("p-dropOverlay")
				return if _.isUndefined e.dataTransfer
				data = {}
				data.files= _.map e.dataTransfer.files,(item)->
					return _.pick item,'name','path','size','type','lastModifiedDate'
				if not data.files[0].path
					return alert "please use node-webkit to drag and drop files"
				@trigger "drag&drop",data)
		remove:()->
			$(@options.dom[0]).off('dragover')
			.off('dragleave')
			.off('drop')
	return DragAndDrop
