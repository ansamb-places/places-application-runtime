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
module = require process.cwd()+"/lib/utils/staticMiddleware"
fake_sendfile = sinon.spy()
describe 'express static middleware',->

	it 'should use the correct file system path when requesting a file',->
		middleware = module "/test","/tmp"
		middleware({originalUrl:"http://localhost:8080/test/my_file.txt"},{sendfile:fake_sendfile})
		expect(fake_sendfile.calledWith("/tmp/my_file.txt")).to.be.true

	it 'should escape GET parameters to create the file path',->
		middleware = module "/test/","/tmp/"
		middleware({originalUrl:"http://localhost:8080/test/my_file.txt?param1=ok&param2=test"},{sendfile:fake_sendfile})
		expect(fake_sendfile.calledWith("/tmp/my_file.txt")).to.be.true

	it 'should respect the file path tree as defined in the url',->
		middleware = module "/test","/tmp"
		middleware({originalUrl:"http://localhost:8080/test/subdir1/subdir2/my_file.txt"},{sendfile:fake_sendfile})
		expect(fake_sendfile.calledWith("/tmp/subdir1/subdir2/my_file.txt")).to.be.true