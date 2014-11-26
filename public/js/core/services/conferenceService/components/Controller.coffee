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
	'cs!app'
	'cs!../views/ConferenceView'
	'cs!../views/CallView'
	'cs!../../../backend_api/AccountBackendAPI'
	'cs!./UserStream'
	'cs!../../../backend_api/PlaceBackendAPI'
	'cs!../../../backend_api/MessageBackendAPI'
	'cs!../entities/Peers'
	'backboneEventStandalone'
	'cs!../../contactsService/index'
	'cs!./WebRTC'
	'cs!../../../backend_api/CredentialBackendAPI'
	'cs!node-webkit/window.coffee'
],(App, ConferenceView, CallView, accountAPI, UserStream, placeBackendAPI, messageBackendAPI, Peers,
backboneEventStandalone, ContactsService, WebRTC, credentialAPI, nw_win) ->
	peers = null
	conferenceWindow = null
	conferenceView = null
	dialog_view = null
	_credential = null
	refreshIceTimeout = null
	negotiating = false
	iceServers = null
	listen = (object,event,callback) ->
		object.off event, callback
		object.on event, callback
	once = (object,event,callback) ->
		object.off event, callback
		object.once event, callback
	controller =
		handleCameraToggle: ->
			conferenceView.off 'conference:camera', controller.handleCameraToggle
			audioConstraint =  UserStream.stream.getAudioTracks()[0].enabled
			conferenceView.toggleCamera()
			if UserStream.stream.getVideoTracks()[0]?
				constraints = {audio: true, video: false}
			else
				constraints = {audio: true, video: true}
			_.each peers.models, (peer) ->
				peer.get('peerConnection').removeStream UserStream.stream
			UserStream.stop()
			UserStream.init constraints, (err, stream) ->
				if err is null and stream?
					UserStream.stream.getAudioTracks()[0].enabled = false if !audioConstraint
					accountAPI.getProfile().done (profile) ->
						conferenceView.collection.findWhere({uid: profile.uid}).set('stream_url', window.URL.createObjectURL(stream))
						_.each peers.models, (peer) ->
							peer.get('peerConnection').addStream UserStream.stream
							controller.negotiate(peer)

		handleMicrophoneToggle: ->
			conferenceView.toggleMicrophone()
			UserStream.toggleMicrophone()
			conferenceView.listenToOnce conferenceView, 'conference:microphone', controller.handleMicrophoneToggle

		listenForCall: ->
			once App.vent, 'conversation:audio:call', controller.handleAudioCallTo
			once App.vent, 'conversation:visio:call', controller.handleVideoCallTo
			backboneEventStandalone.off 'callFrom', controller.handleBusy
			once backboneEventStandalone, 'callFrom', controller.handleCallRequestFrom

		handleAudioCallTo: (ansamber) ->
			App.vent.off 'conversation:audio:call', controller.handleAudioCallTo
			App.vent.off 'conversation:visio:call', controller.handleVideoCallTo
			backboneEventStandalone.off 'callFrom', controller.handleCallRequestFrom
			once backboneEventStandalone, 'callFrom', controller.handleBusy
			controller.handleCallTo {audio: true, video: false}, ansamber

		handleVideoCallTo: (ansamber) ->
			App.vent.off 'conversation:audio:call', controller.handleAudioCallTo
			App.vent.off 'conversation:visio:call', controller.handleVideoCallTo
			backboneEventStandalone.off 'callFrom', controller.handleCallRequestFrom
			once backboneEventStandalone, 'callFrom', controller.handleBusy
			controller.handleCallTo {audio: true, video: true}, ansamber

		handleCallRequestFrom: (ansamber_uid, constraints) ->
			once backboneEventStandalone, 'callFrom', controller.handleBusy
			once backboneEventStandalone, 'abortCall', controller.handleCallAborted
			controller.sendMessage ansamber_uid, {type: 'ringing'}
			ansamber = ContactsService.api.getDataManager().getAnsamberFromUid(ansamber_uid)
			dialog_view = new CallView(ansamber, constraints)
			App.dialogRegion.show dialog_view
			dialog_view.$el.find('#call')[0].play()
			dialog_view.listenToOnce dialog_view, 'close', controller.handleCallViewClose
			dialog_view.listenToOnce dialog_view, 'call:hangUp', controller.handleSelfReject
			dialog_view.listenToOnce dialog_view, 'call:pickUp:audio', controller.handleAudioCallFrom
			dialog_view.listenToOnce dialog_view, 'call:pickUp:video', controller.handleVideoCallFrom

		handleCallAborted: ->
			dialog_view.accept = 'abort'
			dialog_view.rejected()
			setTimeout ->
				dialog_view.close()
			, 4000

		handleCallViewClose: ->
			switch dialog_view.accept
				when 'reject'
					controller.sendMessage dialog_view.model.get('uid'), {type: 'rejectCall'}
					backboneEventStandalone.off 'callFrom', controller.handleBusy
					once backboneEventStandalone, 'callFrom', controller.handleCallRequestFrom
				when 'abort'
					backboneEventStandalone.off 'callFrom', controller.handleBusy
					once backboneEventStandalone, 'callFrom', controller.handleCallRequestFrom

		handleSelfReject: ->
			dialog_view.accept = 'reject'
			dialog_view.close()

		handleAudioCallFrom: ->
			ansamber = dialog_view.model
			dialog_view.accept = 'accept'
			dialog_view.close()
			controller.handleCallFrom {audio: true, video: false}, ansamber

		handleVideoCallFrom: ->
			ansamber = dialog_view.model
			dialog_view.accept = 'accept'
			dialog_view.close()
			controller.handleCallFrom {audio: true, video: true}, ansamber

		handleCallFrom: (options, ansamber) ->
			controller.popConferenceView options, ->
				conferenceView.collection.push {name: ansamber.get('name'), uid: ansamber.get('uid')}
				conferenceView.inConference()
				peers = new Peers.collection()
				peers.push {uid: ansamber.get('uid')}
				controller.getICEServers (ice_server) ->
					iceServers = ice_server
					controller.initializePeers ice_server, ->
						once backboneEventStandalone, 'offer', controller.handleOffer
						once backboneEventStandalone, 'endCall', controller.handleEndCall
						conferenceView.listenToOnce conferenceView, 'conference:hangUp', controller.endCall
						conferenceView.listenToOnce conferenceView, 'conference:microphone', controller.handleMicrophoneToggle
						controller.sendMessage ansamber.get('uid'), {type: 'acceptCall'}

		deletePeers: ->
			peers.each (model) ->
				model.get('peerConnection').close()
				delete model.get('peerConnection')
			peers.reset()

		handleBusy: (ansamber_uid) ->
			controller.sendMessage ansamber_uid, {type: 'busy'}
			once backboneEventStandalone, 'callFrom', controller.handleBusy

		handleCallTo: (options, ansamber) ->
			controller.popConferenceView options, ->
				conferenceView.collection.push {name: "#{ansamber.firstname} #{ansamber.lastname}", uid: ansamber.uid}
				conferenceView.calling()
				peers = new Peers.collection()
				peers.push {uid: ansamber.uid}
				controller.getICEServers (ice_server) ->
					iceServers = ice_server
					controller.initializePeers ice_server, ->
						once backboneEventStandalone, 'acceptCall', controller.handleCallAccepted
						once backboneEventStandalone, 'rejectCall', controller.handleCallRejected
						once backboneEventStandalone, 'busy', controller.handleCallBusy
						once backboneEventStandalone, 'ringing', controller.handleRinging
						conferenceView.listenToOnce conferenceView, 'conference:hangUp', controller.abortCall
						controller.sendMessage ansamber.uid, {type: 'call', constraints: options}

		abortCall: ->
			conferenceView.off 'conference:hangUp', controller.abortCall
			backboneEventStandalone.off 'acceptCall', controller.handleCallAccepted
			backboneEventStandalone.off 'rejectCall', controller.handleCallRejected
			backboneEventStandalone.off 'ringing', controller.handleRinging
			_.each peers.models, (peer) ->
				controller.sendMessage peer.get('uid'), {type: 'abortCall'}
			clearTimeout refreshIceTimeout
			controller.deletePeers()
			conferenceView.selfHangUp()
			UserStream.stop()
			setTimeout ->
				conferenceView.close()
				controller.listenForCall()
			, 4000

		popConferenceView: (userStreamOptions, cb) ->
			accountAPI.getProfile().done (profile) ->
				conferenceView = new ConferenceView({name: "#{profile.firstname} #{profile.lastname}", uid: profile.uid,
				muted: true, self: true}, userStreamOptions)
				window_options =
					position: "center"
					title: "Places - Conference call"
					focus: true
					toolbar: false
					frame: true
					width: 760
					height: 385
					resizable: false
				conferenceWindow = nw_win.newWindow "#{window.location.origin}/conference/", window_options
				conferenceWindow.on 'loaded', ->
					conferenceWindow.window.afterLoaded = ->
						conferenceView.listenToOnce conferenceView, 'close', ->
							conferenceWindow.close(true)
						conferenceWindow.on 'close', controller.endCall
						conferenceWindow.window.conferenceApp.conferenceRegion.show conferenceView
						UserStream.init userStreamOptions, (err, stream) ->
							if err is null and stream?
								conferenceView.collection.findWhere({uid: profile.uid}).set('stream_url', window.URL.createObjectURL(stream))
								cb()


		initializePeers: (iceServers, cb) ->
			_.each peers.models, (peer) ->
				WebRTC.createPeerConnection iceServers, (peerConnection) ->
					peerConnection.onaddstream = (event) ->
						conferenceView.collection.findWhere({uid: peer.get('uid')})
						.set 'stream_url', window.URL.createObjectURL(event.stream)
					peerConnection.onicecandidate = (event) ->
						controller.sendMessage peer.get('uid'), {type: 'ice', ice: event.candidate} if event.candidate?
					peer.set 'peerConnection', peerConnection
			cb()

		getICEServers: (cb) ->
			credentialAPI.getCredential('voip').done (credential) ->
				_credential = credential
				ice_servers = _.map _credential.url, (url) ->
					if _credential.username? and _credential.password?
						return {url: url, username: _credential.username, credential: _credential.password}
					else
						return {url: url}
				cb {'iceServers': ice_servers}
				refreshIceTimeout = setTimeout controller.refreshIce, (_credential.timeout * 750)
			.fail (error) ->
				# TODO : add defaults servers
				cb {'iceServers': [{'url': 'stun:172.16.11.12:3478', 'credential': 'test', 'username': 'test'},
				{'url': 'turn:172.16.11.12:3478', 'credential': 'test', 'username': 'test'}]}

		refreshIce: ->
			credentialAPI.extendCredential('voip', {username: _credential.username, password: _credential.password})
			.done (data) ->
				_credential = _.extend _credential,data
				refreshIceTimeout = setTimeout controller.refreshIce, (_credential.timeout * 750)

		handleRinging: ->
			conferenceView.ringing()

		handleCallAccepted: ->
			backboneEventStandalone.off 'acceptCall', controller.handleCallAccepted
			backboneEventStandalone.off 'rejectCall', controller. handleCallRejected
			backboneEventStandalone.off 'ringing', controller.handleRinging
			backboneEventStandalone.off 'busy', controller.handleCallBusy
			conferenceView.off 'conference:hangUp', controller.abortCall
			conferenceView.listenToOnce conferenceView, 'conference:hangUp', controller.endCall
			once backboneEventStandalone, 'endCall', controller.handleEndCall
			conferenceView.inConference()
			conferenceView.listenToOnce conferenceView, 'conference:microphone', controller.handleMicrophoneToggle
			once backboneEventStandalone, 'offer', controller.handleOffer
			_.each peers.models, (peer) ->
				controller.negotiate(peer)

		endCall: ->
			conferenceView.off 'conference:hangUp', controller.abortCall
			backboneEventStandalone.off 'ice', controller.handleIce
			backboneEventStandalone.off 'offer', controller.handleOffer
			backboneEventStandalone.off 'answer', controller.handleAnswer
			backboneEventStandalone.off 'endCall', controller.handleEndCall
			_.each conferenceView.collection.models, (model) ->
				controller.sendMessage(model.get('uid'), {type: 'endCall'}) if model.get('self') is false
				model.set 'stream_url', ''
			clearTimeout refreshIceTimeout
			controller.deletePeers()
			conferenceView.selfHangUp()
			UserStream.stop()
			setTimeout ->
				conferenceView.close()
				controller.listenForCall()
			, 4000

		handleCallRejected: ->
			backboneEventStandalone.off 'rejectCall', controller. handleCallRejected
			backboneEventStandalone.off 'acceptCall', controller.handleCallAccepted
			backboneEventStandalone.off 'busy', controller.handleCallBusy
			backboneEventStandalone.off 'ringing', controller.handleRinging
			clearTimeout refreshIceTimeout
			controller.deletePeers()
			conferenceView.rejected()
			_.each conferenceView.collection.models, (model) ->
				model.set 'stream_url', ''
			UserStream.stop()
			setTimeout ->
				conferenceView.close()
				controller.listenForCall()
			, 4000

		handleCallBusy: ->
			backboneEventStandalone.off 'rejectCall', controller. handleCallRejected
			backboneEventStandalone.off 'acceptCall', controller.handleCallAccepted
			backboneEventStandalone.off 'busy', controller.handleCallBusy
			backboneEventStandalone.off 'ringing', controller.handleRinging
			clearTimeout refreshIceTimeout
			controller.deletePeers()
			conferenceView.busy()
			_.each conferenceView.collection.models, (model) ->
				model.set 'stream_url', ''
			UserStream.stop()
			setTimeout ->
				conferenceView.close()
				controller.listenForCall()
			, 4000

		handleEndCall: ->
			conferenceView.off 'conference:hangUp', controller.abortCall
			backboneEventStandalone.off 'ice', controller.handleIce
			backboneEventStandalone.off 'offer', controller.handleOffer
			backboneEventStandalone.off 'answer', controller.handleAnswer
			backboneEventStandalone.off 'endCall', controller.handleEndCall
			clearTimeout refreshIceTimeout
			_.each conferenceView.collection.models, (model) ->
				model.set 'stream_url', ''
			controller.deletePeers()
			conferenceView.rejected()
			UserStream.stop()
			setTimeout ->
				conferenceView.close()
				controller.listenForCall()
			, 4000

		negotiate: (peer) ->
			backboneEventStandalone.off 'ice', controller.handleIce
			conferenceView.off 'conference:camera', controller.handleCameraToggle
			WebRTC.generateOffer peer.get('peerConnection'), (offer) ->
				negotiating = true
				once backboneEventStandalone, 'answer', controller.handleAnswer
				controller.sendMessage peer.get('uid'), {type: 'offer', offer: offer}

		handleOffer: (ansamber_uid, offer) ->
			backboneEventStandalone.off 'ice', controller.handleIce
			conferenceView.off 'conference:camera', controller.handleCameraToggle
			if negotiating and conferenceView.collection.findWhere({self: true}).get('uid') < ansamber_uid
				peer = peers.findWhere({uid: ansamber_uid})
				peer.get('peerConnection').close()
				WebRTC.createPeerConnection iceServers, (peerConnection) ->
					peerConnection.onaddstream = (event) ->
						conferenceView.collection.findWhere({uid: ansamber_uid})
						.set 'stream_url', window.URL.createObjectURL(event.stream)
					peerConnection.onicecandidate = (event) ->
						controller.sendMessage ansamber_uid, {type: 'ice', ice: event.candidate} if event.candidate?
					peer.set('peerConnection', peerConnection)
					negotiating = false
					controller.handleOffer ansamber_uid, offer
			else
				WebRTC.handleOffer peers.findWhere({uid: ansamber_uid}).get('peerConnection'), offer, (answer) ->
					controller.sendMessage ansamber_uid, {type: 'answer', answer: answer}
					listen backboneEventStandalone, 'ice', controller.handleIce
					conferenceView.listenToOnce conferenceView, 'conference:camera', controller.handleCameraToggle
					once backboneEventStandalone, 'offer', controller.handleOffer

		handleAnswer: (ansamber_uid, answer) ->
			WebRTC.handleAnswer peers.findWhere({uid: ansamber_uid}).get('peerConnection'), answer, ->
				listen backboneEventStandalone, 'ice', controller.handleIce
				conferenceView.listenToOnce conferenceView, 'conference:camera', controller.handleCameraToggle

		handleIce: (ansamber_uid, ice) ->
			peerConnection = peers.findWhere({uid: ansamber_uid}).get('peerConnection')
			if peerConnection.signalingState is 'stable'
				peerConnection.addIceCandidate new RTCIceCandidate(ice)

		handleMessage: (remote,payload) ->
			# console.log "received",payload,"from",remote
			switch payload.type
				when 'call'
					backboneEventStandalone.trigger 'callFrom', remote, payload.constraints
				when 'ringing'
					backboneEventStandalone.trigger 'ringing'
				when 'rejectCall'
					backboneEventStandalone.trigger 'rejectCall', remote
				when 'abortCall'
					backboneEventStandalone.trigger 'abortCall', remote
				when 'acceptCall'
					backboneEventStandalone.trigger 'acceptCall', remote
				when 'endCall'
					backboneEventStandalone.trigger 'endCall', remote
				when 'offer'
					backboneEventStandalone.trigger 'offer', remote, payload.offer
				when 'answer'
					backboneEventStandalone.trigger 'answer', remote, payload.answer
				when 'ice'
					backboneEventStandalone.trigger 'ice', remote, payload.ice
				when 'busy'
					backboneEventStandalone.trigger 'busy'

		sendMessage: (remote,payload) ->
			# console.log "sending",payload,"to",remote
			placeBackendAPI.getUniqueConversationPlace(remote).done (response) ->
				place_id = response.id
				messageBackendAPI.sendMessage 'voip', place_id, remote, payload

	return controller
