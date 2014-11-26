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
	'ansamb_context',
	'text!template/activityFeedPost.tmpl',
	'cs!js/Model'
	],(c,tmpl,Model)->
	class WallView extends Backbone.Marionette.View
		# className:'animated fadeInRight'
		className : 'p-post-content'
		initialize:(options)->
			@placeName = options.placeName||"default"
			@template = _.template tmpl
			@syncWithApp = _.isUndefined(options.data)
			@listenTo @model,'change:backend_synced',@syncedChange
		render:=>
			@$el.empty()
			@$el.html "Loading ..."
			@$el.html @template(@model.toJSON())
			@
		events:
			'click':'onClick'
		onClick:->
			console.log "content clicked"
		syncedChange:->
			console.log "model synced"
	return WallView