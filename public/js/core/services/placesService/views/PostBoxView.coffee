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
	'text!../templates/postBox.tmpl',
	]
,(tmpl)->
	return class PostBoxView extends Backbone.Marionette.ItemView
		initialize:(options)->
			@template= _.template tmpl,{placeName:options.placeName}
		template:=>
			return @template()
		ui:
			post:'.postinput'
		events:
			"click a":"writePost"
			'keydown input':'writePost'
		writePost:(e)->
			if e.type == "keydown"
				if e.keyCode != 13
					return
			e.preventDefault()
			e.stopPropagation()
			if @ui.post.val() != ""
				@trigger "post",{post:@ui.post.val()}
			@ui.post.val("")