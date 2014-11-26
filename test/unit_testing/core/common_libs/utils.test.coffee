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

module = require process.cwd()+"/core/common_lib/utils"
object =
	attr1:"secret_password"
	attr2:"test"
	get_password:->
		return @attr1
	set_password:(password)->
		@attr1 = password if typeof password=="string" and password.length>5

describe 'core utils',->
	describe 'callbacks helper',->

		it 'should call one or another callback depending on the the returned function result',->
			fun1 = sinon.spy()
			fun2 = sinon.spy()
			fun3 = sinon.spy()
			fun4 = sinon.spy()

			main_cb1 = module.errorCatchCb fun1,fun2
			main_cb2 = module.errorCatchCb fun3,fun4

			main_cb1 "error",true,"arg2"
			main_cb2 null,"ok"

			expect(fun1.called).to.be.true
			expect(fun1.calledWith("error")).to.be.true
			expect(fun2.called).to.be.false
			expect(fun3.called).to.be.false
			expect(fun4.called).to.be.true

		it 'should propagate all arguments to the sucess callback',->
			fun1 = sinon.spy()
			fun2 = sinon.spy()

			main_cb = module.errorCatchCb fun1,fun2
			main_cb null,true,"arg2"

			expect(fun2.calledWithExactly(null,true,"arg2")).to.be.true

	describe 'clone object helper',->

		it 'should clone an object in keeping only the functions and not the other attributes',->
			o = module.methodObj(object)
			expect(o).to.not.have.keys("attr1","attr2")
			expect(o).to.have.property("get_password").and.to.be.a("function")

		it 'cloned functions should be bound to the original object',->
			o = module.methodObj(object)
			object.attr1 = "secret_password2"
			expect(o.get_password()).to.be.equal(object.attr1)

	describe 'place_id parser',->

		it 'should return null if the place_id is not a valid one',->
			expect(module.parsePlaceId "wrong_place_name").to.be.null
			expect(module.parsePlaceId "@ok").to.be.null

		it 'should extract the place uid and owner from the place id',->
			res = module.parsePlaceId "place_uid@owner"
			expect(res).to.be.have.keys("uuid","owner_uid")
			expect(res.uuid).to.be.equal("place_uid")
			expect(res.owner_uid).to.be.equal("owner")


