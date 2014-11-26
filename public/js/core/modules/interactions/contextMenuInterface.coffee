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
define ['jquery.ui-contextmenu'],()->
	contextMenuInterface=
		enhanceView:(View)->
			render= View::render		
			View::render=()->
				render.call(@,arguments)
				if @contextMenu?.length>0
					@$el.contextmenu({
						preventContextMenuForPopup: true,
						preventSelect: true,
						taphold: true,
						show:false,
						menu: @contextMenu
						beforeOpen: (event, ui)=>
							if @contextMenuInstance.disabled == true
								return false
							event.stopPropagation()
						select: (event, ui)=>
							@contextMenuInstance.trigger_el.trigger "contextmenu:#{ui.cmd}" if ui.cmd
					})
					@contextMenuInstance=
						change_trigger_el:(el)->
							@trigger_el=el
						disable:()->
							@disabled= true
						enable:()->
							@disabled= false
						reset:()=>
							@$el.contextmenu("replaceMenu", @contextMenu)
							@contextMenuInstance.trigger_el= @
							@contextMenuInstance.disabled= false
						change_menu:(menu)=>
							@$el.contextmenu("replaceMenu", menu)
						disabled: false
						trigger_el: @
				return @
	contextMenuInterface.enhanceView(Backbone.Marionette.ItemView)
	contextMenuInterface.enhanceView(Backbone.Marionette.CompositeView)
	return contextMenuInterface
