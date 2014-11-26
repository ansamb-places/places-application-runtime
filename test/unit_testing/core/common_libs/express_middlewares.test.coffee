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

fake_res = {send:(obj)->return}
module = require process.cwd()+"/core/common_lib/express_middlewares"

describe 'express middlewares',->
	
	describe 'place_name require',->

		it 'should reply to the request with an error if the place_name is missing',->
			fake_req = {query:{}}
			mock = sinon.mock(fake_res)
			mock.expects("send").once().withArgs(sinon.match.has("err"))
			
			module.require_place_name fake_req,fake_res,null
			
			mock.verify()
			mock.restore()

		it 'should called the next middleware with the place_name appended to the request object',->
			fake_req = {query:{place_name:"my_place"}}
			next = sinon.spy()
			
			module.require_place_name fake_req,fake_res,next
			
			expect(next.called).to.be.true
			expect(fake_req).to.have.ownProperty("place_name")
			expect(fake_req.place_name).to.be.equal("my_place")