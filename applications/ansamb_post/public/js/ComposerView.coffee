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
	'text!template/ComposerView.tmpl',
],(tmpl)->
	return class ComposerView extends Backbone.Marionette.ItemView
		tagName:'div'
		className:'p-file-container'
		template:->
			return tmpl
		ui:
			post:'.postinputarea'
		events:
			"click a":"writePost"
			"focusin" : "expand"
			'keydown input':'writePost'
			"click .application-list li":'applicationSelect'
		writePost:(e)->
			if e.type == "keydown"
				if e.keyCode != 13
					return
			e.preventDefault()
			e.stopPropagation()
			if @ui.post.val() != ""
				@trigger "content:new",{post:@ui.post.val()}
			@ui.post.val("")
		expand:(e) ->
			@trigger "view:expand"

		getData : ->
			return {post:@ui.post.val()}

		deleteData: ->
			@ui.post.val('')
