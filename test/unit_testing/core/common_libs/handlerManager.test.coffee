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

module = require process.cwd()+"/core/common_lib/HandlerManager"
mock = null
manager = null

describe 'Handler manager module',->
	
	beforeEach ->
		manager = new module()
		mock = sinon.mock(manager)
	
	afterEach ->
		mock.restore()
		manager = null

	it 'should correctly bind the object context to all methods',->

		mock.expects("getHandler").on(manager)
		mock.expects("registerHandler").calledOn(manager)
		mock.expects("cleanHandlers").calledOn(manager)

		manager.getHandler()
		manager.registerHandler 'test',->
		manager.cleanHandlers()

		mock.verify()

	it 'should correctly save handlers for the given key',->

		handler1 = ->
		handler2 = ->
		manager.registerHandler 'test',handler1
		manager.registerHandler 'test2',handler2

		expect(manager.getHandler('test')).to.be.equal(handler1)
		expect(manager.getHandler('test')).to.not.be.equal(handler2)
		expect(manager.getHandler('test2')).to.be.equal(handler2)

	it 'should correctly clean all handlers',->

		manager.registerHandler 'test',->
		manager.registerHandler 'test2',->
		manager.cleanHandlers()

		expect(manager.getHandler('test')).to.be.undefined
		expect(manager.getHandler('test2')).to.be.undefined