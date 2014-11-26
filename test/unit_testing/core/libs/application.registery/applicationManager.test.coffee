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
env = require '../env'
path = require 'path'

module = require path.join(env.base_path,"application.registery","ApplicationManager")
base_path = path.join(__dirname,'_applications')
_manager = null

describe 'Application manager module',->
	before ->
		_manager = new module(base_path)
		_manager.autoload()

	it 'should autoload applications synchronously',->
		mock = sinon.mock()
		mock.atLeast(2)
		manager = new module(base_path)
		manager.on 'loading_app:done',mock
		expect(Object.keys(manager.getApplications())).to.have.length(0)
		manager.autoload()
		expect(Object.keys(manager.getApplications())).to.have.length(2)
		mock.verify()

	it 'should generate a report after application loading',->
		manager = new module(base_path)
		report = manager.autoload()
		expect(report).to.be.an('object')

	it 'should not register applications which are not valid (not expose all required interfaces)',->
		manager = new module(base_path)
		reply1 = manager.registerApplication path.join(base_path,"application2_nv")
		reply2 = manager.registerApplication path.join(base_path,"application4_nv")
		expect(reply1.loaded).to.be.false
		expect(reply2.loaded).to.be.false
		expect(Object.keys(manager.getApplications())).to.have.length(0)

	it 'should return an application based on its name or null if not exists',->
		app = _manager.getAppByName "application1"
		expect(app).to.be.an('object').that.have.property('module').that.is.an('object')
		expect(app).to.have.property('path').that.is.a('string')
		expect(app).to.have.property('contentType').that.is.a('string')
		expect(_manager.getAppByName("notexists")).to.be.null

	it 'should return all applications which are dealing with the file system',->
		apps = _manager.getApplicationsWithStorage()
		expect(apps).to.have.length(1)

	it 'should return applications descriptors without the module object when requested',->
		apps = _manager.getSanitizedApplications()
		expect(apps[Object.keys(apps)[0]]).to.not.have.property("module")
		expect(apps[Object.keys(apps)[0]]).to.have.property("name")

	it 'should return an array with all models\' directories of each application',->
		models = _manager.getAllDbModelsPath()
		expect(Object.keys(models)).to.have.length(2)
		expect(models[Object.keys(models)[0]]).to.be.equal(__dirname+"/_applications/application1/models")
		expect(models[Object.keys(models)[1]]).to.be.equal(__dirname+"/_applications/application3/models")

	it 'should return an application based on its content-type',->
		app = _manager.getApplicationForContentType "file"
		expect(app).to.be.an('object').that.have.property("name","application1")

	it 'should correctly initialize an application',(done)->
		router = {
			on:->
			static:->
		}
		mockRouter = sinon.mock(router)
		mockRouter.expects("on").twice()
		mockRouter.expects("static").once()
		mockManager = sinon.mock(_manager)
		mockManager.expects("checkMigrationForPlaceApp").once().withArgs("application1").yields(null,true,"0.0.1")
		
		app = _manager.getAppByName "application1"
		expect(app.initialized).to.be.false

		_manager.initApplication "application1",router,null,[],(err,migrated)->
			mockRouter.verify()
			mockManager.verify()
			mockManager.restore()
			expect(migrated).to.be.true
			expect(err).to.be.null
			expect(app.initialized).to.be.true
			done()
