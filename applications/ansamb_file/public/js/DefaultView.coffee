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
	'text!template/default.tmpl',
	'text!template/default-popup.tmpl',
	'cs!js/pluginLoader'
	],(FileView,tmpl,ptmpl,pl)->
	class ItemView extends FileView
		initialize:(options)->
			super(options)
			@templates.gallery[1] = tmpl
			@templates.wall[1] = tmpl
			if options.popup
				@template= _.template ptmpl
		preview:(e)->
			e.preventDefault() if e
			options= @options
			options.hide= false
			options.tagName= 'div'
			options.popup= true
			options.type= null
			@context.createDialog new ItemView options
		open:(e)->
			e.preventDefault() if e
			pl.openFile(@model.get('data').name,@place_id)

