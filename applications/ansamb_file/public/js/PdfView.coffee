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
	'text!template/pdf.tmpl',
	'cs!js/pluginLoader'
	],(FileView,tmpl,pl)->
	class ItemView extends FileView
		initialize:(options)->
			super(options)
			@mode_preview= true
			@templates.gallery[1] = tmpl
			@templates.wall[1] = tmpl
		preview:(e)->
			e.preventDefault() if e
			#url is not in the model, we need to reCall serializeData to obtain it 
			pl.openPdf(@serializeData().data.url)