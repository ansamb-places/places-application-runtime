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
proxyquire = require 'proxyquire'
sinon = require 'sinon'
_ = require 'underscore'

framework = null
module = null

describe 'Server link management',->

	before (done)->
		@timeout(5000)
		core = require process.cwd()
		core.defer.promise.then (_framework)->
			framework = _framework
			module = framework.getService("server_link_management")
			framework.getService("server").stepManager.disableFiltering()
			expect(module).to.be.an("object")
			done()

	describe 'protocol builder',->

		it 'should exists',->
			expect(framework.getService("protocol.builder").link_mgmt).to.be.an('object')

	describe 'API',->

		describe 'method setStatus',->

			it 'should emit an event through the module',->
				spy = sinon.spy()
				module.on 'status:change',spy

				module.setStatus(module.status.connected)

				expect(spy.calledOnce).to.be.true

			it 'should trigger an event onto the event bus if notify_ui option is defined',->
				events = framework.getService('events').emitter
				spy = sinon.spy(events,'emit')

				module.setStatus(module.status.connected,{notify_ui:true})

				events.emit.restore()
				expect(spy.withArgs("server_link:status:change",module.status.connected).calledOnce).to.be.true

		describe 'method getStatus',->

			it 'should returned the stored status if no callback is defined when calling getStatus',->
				module.setStatus(module.status.connected)
				expect(module.getStatus()).to.be.equal(module.status.connected)

			it 'should send a network message when asking for the status with a callback',(done)->
				com_layer = framework.getService("communication_layer")
				spy = sinon.spy(com_layer,"send")

				message_match = sinon.match
					method:"STATUS_GET"

				module.getStatus (err,status)->
					com_layer.send.restore()
					expect(err).to.be.null
					expect(spy.withArgs(message_match).calledOnce).to.be.true
					done()

		describe 'method connect',->
			it 'should send a network message to try to connect',(done)->
				com_layer = framework.getService("communication_layer")
				spy = sinon.spy(com_layer,"send")

				message_match = sinon.match
					method:"CONNECT"

				module.connect (err,connected)->
					com_layer.send.restore()
					expect(spy.withArgs(message_match).calledOnce).to.be.true
					done()

		describe 'method isLinkConnected',->

			it 'should use api.getStatus to know if the link is connected or not',->
				spy = sinon.spy(module,'getStatus')

				module.isLinkConnected()

				module.getStatus.restore()
				expect(spy.calledOnce).to.be.true

			it 'should return true if the link is connected',->
				module.setStatus(module.status.connected)

				connected = module.isLinkConnected()

				expect(connected).to.be.true

	describe 'protocol handler',->

		it 'should call setStatus when receive the correct message from the kernel',(done)->
			spy = sinon.spy(module,'setStatus')

			message =
				protocol:'link_mgmt'
				method:'STATUS_CHANGE'
				data:
					status:'connected'
			framework.getService('communication_layer').inject(message)

			setTimeout ->
				module.setStatus.restore()
				expect(spy.calledOnce).to.be.true
				done()
			,50
