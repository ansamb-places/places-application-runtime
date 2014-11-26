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
fs = require 'fs'
sinon = require 'sinon'

fake_list = ['.DS_Store','test','ds_store']
readdir = null
readdirSync = null
module = null

describe 'Safe FS lib',->

	before ->
		readdir = sinon.stub(fs,"readdir")
		readdir.withArgs('test').yields(null,fake_list)
		readdirSync = sinon.stub(fs,"readdirSync")
		readdirSync.withArgs('test').returns(fake_list)
		module = proxyquire process.cwd()+"/lib/safeFs",
			fs:
				readdirSync:readdirSync
				readdir:readdir
	after ->
		readdir.restore()
		readdirSync.restore()

	it 'should return all directories without .DS_Store synchronously',->
		files = module.readdirSync 'test'
		expect(files).to.be.an('array')
		expect(files.length).to.be.equal(2)
		expect(files).not.include '.DS_Store'

	it 'should return all directories without .DS_Store asynchronously',(done)->
		module.readdir 'test',(err,files)->
			expect(files).to.be.an('array')
			expect(files.length).to.be.equal(2)
			expect(files).not.include '.DS_Store'
			done()