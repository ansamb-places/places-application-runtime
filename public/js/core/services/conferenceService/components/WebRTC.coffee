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
	'cs!./UserStream'
	'backboneEventStandalone'
],(UserStream,backboneEventStandalone)->
	class WebRTC
		constructor:()->
			_.extend(@, backboneEventStandalone)
			@peerConnectionOptions = {'optional': [{'DtlsSrtpKeyAgreement': false}]}
		createPeerConnection:(iceServers, cb)->
			peerConnection = new webkitRTCPeerConnection iceServers, @peerConnectionOptions
			peerConnection.addStream UserStream.stream
			cb peerConnection
		generateOffer:(peerConnection, cb)->
			peerConnection.createOffer (offer)->
				peerConnection.setLocalDescription new RTCSessionDescription(offer), ->
					cb offer
		handleOffer:(peerConnection, offer, cb)->
			peerConnection.setRemoteDescription new RTCSessionDescription(offer), ()->
				peerConnection.createAnswer (answer)=>
					peerConnection.setLocalDescription new RTCSessionDescription(answer), ()->
						cb answer
		handleAnswer:(peerConnection, answer, cb)->
			peerConnection.setRemoteDescription new RTCSessionDescription(answer), ()->
				cb()
	return new WebRTC