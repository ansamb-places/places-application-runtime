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
define ['text!./content.tmpl'],(tmpl)->
	return Backbone.Marionette.Layout.extend {
		tagName: 'div'
		className: 'p-single-content-container row collapse'
		template: _.template(tmpl)
		initialize:(options)->
			@model = options.model
		render:->
			@$el.html @template(@model.toJSON())
			clearInterval @interval if @interval?
			@interval = setInterval @updateTimeago.bind(@),60000
			@updateTimeago()
			@
		regions: 
			content: ".content"
			file_stats: ".file-stats"
			comments: ".activity-comments"

		updateTimeago:->
			@$el.find(".date").html moment.utc(@model.get('date')).fromNow()
	}