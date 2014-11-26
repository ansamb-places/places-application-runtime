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
	'text!../templates/placesHeaderSearch.tmpl'
	],(tmpl)->
	class PlaceHeaderSearchView extends Backbone.Marionette.ItemView
		template: _.template tmpl
		view_type:'#thumb'
		ui:
			"#most_recent":"most_recent"
			"#favorite":"favorite"
			"#alpha":"alpha"
			"#list":"list"
			"#thumb":"thumb"
		events:
			"click #most_recent":"sort"
			"click #favorite":"sort"
			"click #alpha":"sort"
			"click #list":"view"
			"click #thumb":"view"
		sort:(e)->
			target= $(e.target)
			if target.hasClass('selected')
				target.removeClass('selected')
			else 
				target.addClass('selected')
		view:(e)->
			target= $(e.target)
			if !target.hasClass('selected')
				$(@view_type).removeClass('selected')
				target.addClass('selected')
				@view_type='#'+target.attr('id')
				target.hasClass('selected')
				@trigger "get:#{target.attr('id')}"