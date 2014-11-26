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
	'cs!../views/AnsamberItemView'
	'text!../templates/params.tmpl'
	],(AnsamberView,tmpl)->
	class ParamsView extends Backbone.Marionette.CompositeView
		tagName:'div'
		className: 'p-single-content-page p-full-page'
		itemView: AnsamberView
		itemViewContainer: "ul"
		template:->
			return tmpl
		initialize:(options)->
			@collection = options.collection
			@place = options.place
		ui:
			uid:'.adduid'
		events:
			"click .addAnsamber":"addAnsamber"
		onRender:->
			owner = @place.get('owner_uid')
			##Drag and drop actions
			@$el.droppable
				scope:'ansamber'
				hoverClass:"drop-hover"
				tolerance:"intersect"
				drop:(event,ui)=>
					if owner==null
						uid = ui.draggable.data('uid')
						@trigger "ansamber:add",uid
					@showOverlay(false)
				over:(event,ui)=>
					if owner?
						@showOverlay(true,"You're not the owner of the place so you can't add contact to it")
					else
						uid = ui.draggable.data('uid')
						@showOverlay(true)
				out:(event,ui)=>
					@showOverlay(false)
		showOverlay:(show,message)=>
			overlay = @$el.find('.dropOverlay')
			if show
				if not _.isUndefined message
					overlay.find('.notif').html message
				else
					overlay.find('.notif').html '<span class="entypo">&#59136;</span> Drop to add the Ansamber'
			if show then overlay.fadeIn('fast') else overlay.fadeOut('fast')
		addAnsamber:(e)->
			e.preventDefault()
			@trigger "ansamber:add",@ui.uid.val()
