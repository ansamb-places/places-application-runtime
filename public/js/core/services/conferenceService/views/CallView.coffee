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
	'text!../templates/Call.tmpl'
],(tmpl)->
	class CallView extends Backbone.Marionette.ItemView
		events:
			'click .trigger':'actionTrigger'
		actionTrigger:(e)->
			action = $(e.currentTarget).data('action')
			@trigger "call:#{action}", @
		initialize:(ansamber, constraints)->
			@model = new Backbone.Model {uid: ansamber.get('uid'), name: ansamber.get('firstname') + ' ' + ansamber.get('lastname')}
			@accept = 'reject'
			@constraints = constraints
		template:(model)=>
			_.extend model, @constraints
			return _.template tmpl,model
		rejected:()->
			@$el.find('.info').text @model.escape('name') + ' hanged up !'
			@$el.find('.inputs').toggle false
			@$el.find('#call')[0].pause()
	return CallView