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
expect = require('chai').expect
sinon = require 'sinon'

framework = null
module = null

describe 'api.place.message lib',->

	before (done)->
		@timeout(10000)
		core = require process.cwd()
		core.defer.promise.then (_framework)->
			framework = _framework
			module = framework.getService("api.place.message")
			done()

	describe 'PUT',->
		place = null
		content_type = 'voip'
		src = 'test_src'
		dst = 'test_dst'
		payload = {type:'offer',offer:'test_offer'}

		before (done)->
			@timeout(13000)
			id = framework.getService("api.place").createPlaceId("share",null,null).place_id
			framework.getService("api.place").addPlace {
				id:id
				name:"test__"+new Date
				type:"share"
				owner_uid:null
			},{auto_validate:true,wait_validation:true},(err,_place)->
				expect(err).to.be.null
				expect(_place).to.be.an("object")
				place = _place
				done()

		after (done)->
			framework.getService("api.place").deletePlaceById place.id,(err,deleted)->
				done()

		it 'should send a network message',(done)->
			@timeout(13000)
			com_layer = framework.getService("communication_layer")
			spy = sinon.spy(com_layer,"send")

			module.sendMessage place.id, dst, content_type, payload, (data)->
				match = sinon.match
					protocol:"message"
					method:"PUT"
					dst:dst
					data:payload
					content_type:content_type

				expect(spy.withArgs(match).calledOnce).to.be.true
				com_layer.send.restore()
				done()

		it 'should emit a message event through the event service on message',(done)->
			events = framework.getService("events")
			spy = sinon.spy(events.emitter,"emit")
			framework.getService("communication_layer").inject {ver:1, protocol: 'message', method: 'PUT', data: payload, src: src, content_type: content_type}
			expect(spy.withArgs("message:"+content_type,src,payload).calledOnce).to.be.true
			events.emitter.emit.restore()
			done()
