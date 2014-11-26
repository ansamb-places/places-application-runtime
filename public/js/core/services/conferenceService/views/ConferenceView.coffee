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
	'text!../templates/Conference.tmpl'
	'cs!./SpeakerView'
	'cs!../entities/Speakers'
	'cs!../../../node-webkit/window'
],(tmpl,SpeakerView,Speakers,nw_window)->
	class ConferenceView extends Backbone.Marionette.CompositeView
		className: 'conference-view'
		itemView:SpeakerView
		itemViewContainer:'.speakers'
		events:
			'click .trigger':'actionTrigger'
		model: new Backbone.Model {audio: false, video: false}
		actionTrigger:(e)->
			action = $(e.currentTarget).data('action')
			@trigger "conference:#{action}", @
		template:(model)->
			return _.template tmpl,model
		initialize:(self, userStreamOptions)->
			@collection = new Speakers.collection self
			@model.set userStreamOptions
			@listenTo @model, 'change', @render
		calling:->
			@$el.find('.info').text 'Calling ' + @collection.findWhere({self:false}).get('name') + ' ...'
		inConference:->
			@$el.find('.info').text 'In conference with ' + @collection.findWhere({self:false}).get('name') + ' ...'
			@$el.find('#ringing')[0].pause()
		selfHangUp:->
			@$el.find('.inputs').toggle false
			@$el.find('.info').text 'You hanged up !'
			@$el.find('#ringing')[0].pause()
		ringing:->
			@$el.find('.info').text 'Ringing ...'
			@$el.find('#ringing')[0].play()
		rejected:->
			@$el.find('.info').text @collection.findWhere({self:false}).get('name') + ' hanged up !'
			@$el.find('.inputs').toggle false
			@$el.find('#ringing')[0].pause()
		toggleCamera:->
			@model.set {video: !@model.get('video')}
			@inConference()
		toggleMicrophone:->
			@model.set {audio: !@model.get('audio')}
			@inConference()
		busy:->
			@$el.find('.info').text @collection.findWhere({self:false}).get('name') + ' is busy !'
			@$el.find('.inputs').toggle false
	return ConferenceView