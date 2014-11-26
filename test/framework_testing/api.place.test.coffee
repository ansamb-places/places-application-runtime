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
path = require 'path'
fs = require 'fs'

framework = null
module = null

describe 'PLACE API',->

	before (done)->
		@timeout(5000)
		core = require process.cwd()
		core.defer.promise.then (_framework)->
			framework = _framework
			module = framework.getService("api.place")
			expect(module).to.be.an("object")
			#we need to get the account before creating any place
			framework.getService("api.account").getAccount ->
				done()

	describe.skip 'Place delete',->
		place = null

		beforeEach (done)->
			id = module.createPlaceId("share",null,null).place_id
			module.addPlace {
				id:id
				name:"test__"+new Date
				type:"share"
				owner_uid:null
				status:module.status.validated
			},{wait_validation:true},(err,_place)->
				expect(err).to.be.null
				expect(_place).to.be.an("object")
				place = _place
				done()

		afterEach (done)->
			module.deletePlaceById place.id,(err,deleted)->
				done()

		it 'should remove the place from the database',(done)->
			module.deletePlaceById place.id,(err,deleted)->
				expect(err).to.be.null
				module.getPlace place.id,(err,p)->
					expect(err).to.be.equal("Place not found")
					done()

		it 'should return an error if the place not exists',(done)->
			module.deletePlaceById "fake_place",(err,deleted)->
				expect(err).to.not.be.null
				expect(deleted).to.be.false
				module.deletePlaceById place.id,(err,deleted)->
					done()

		it 'should call the deleteDatabase method of database manager',(done)->
			db_manager = framework.getService("database_manager")
			spy = sinon.spy(db_manager,"deleteDatabaseForPlace")
			module.deletePlaceById place.id,(err,deleted)->
				db_manager.deleteDatabaseForPlace.restore()
				expect(err).to.be.null
				expect(spy.withArgs(place.id).calledOnce).to.be.true
				done()

		it 'should emit an delete event through the service itself',(done)->
			spy = sinon.spy()
			module.on "place:delete",spy
			module.deletePlaceById place.id,(err,deleted)->
				expect(err).to.be.null
				expect(spy.withArgs(place.id).calledOnce).to.be.true
				done()

		it 'should send a network message to notify the place members about the deletion and get a correct reply',(done)->
			service = framework.getService("protocol.builder").place
			originalDelete = service.deletePlace
			sendSpy = null
			stub = sinon.stub service,"deletePlace",->
				obj = originalDelete.apply null,arguments
				originalSend = obj.send
				obj.send = (fn)->
					sendSpy = sinon.spy(fn)
					originalSend.call obj,sendSpy
				return obj
			module.deletePlaceById place.id,(err,deleted)->
				service.deletePlace.restore()
				expect(err).to.be.null
				expect(stub.withArgs(sinon.match({place:place.id})).calledOnce).to.be.true
				expect(sendSpy.withArgs(null,sinon.match({spl:place.id,dpl:place.id,code:200})).calledOnce).to.be.true
				done()

		it 'should delete the place\'s folders recursively',(done)->
			app_registery = framework.getService("application.registery")
			app = app_registery.getApplicationForContentType "file"
			app_path = app.file_dir_path
			module.generateFolderNameFromPlaceId place.id,(err,place_path)->
				expect(err).to.be.null
				p = path.join app_path,place_path
				expect(fs.existsSync(p)).to.be.true
				fake_file_path = path.join __dirname,"files","image4.pdf"
				fs.writeFileSync(path.join(p,"fake.pdf"),fs.readFileSync(fake_file_path))
				module.deletePlaceById place.id,(err,deleted)->
					expect(fs.existsSync(p)).to.be.false
					done()

	describe.skip "Place settings udpate",->
		place = null

		before (done)->
			id = module.createPlaceId("share",null,null).place_id
			module.addPlace {
				id:id
				name:"test__"+new Date
				type:"share"
				owner_uid:null
				status:module.status.validated
			},{wait_validation:true},(err,_place)->
				expect(err).to.be.null
				expect(_place).to.be.an("object")
				place = _place
				console.log "\n\n"
				done()

		after (done)->
			console.log "\n\n"
			module.deletePlaceById place.id,(err,deleted)->
				done()

		it 'should update the place settings on a network place_settings PUT',(done)->
			message = 
				message_id:"111111"
				protocol:"content"
				method:"PUT"
				date:+new Date
				src:"ansamb"
				dst:"ansamb"
				spl:place.id
				dpl:place.id
				content_type:"place_settings"
				data:
					uid:place.id
					name:place.name
					status:"disabled"
			framework.getService("communication_layer").inject message
			setTimeout ->
				module.getPlace place.id,(err,place)->
					expect(err).to.be.null
					expect(place.status).to.be.equal("disabled")
					done()
			,300

		it 'should trigger an "update" event through the events service',(done)->
			message = 
				message_id:"111111"
				protocol:"content"
				method:"PUT"
				date:+new Date
				src:"ansamb"
				dst:"ansamb"
				spl:place.id
				dpl:place.id
				content_type:"place_settings"
				data:
					uid:place.id
					name:place.name
					status:"disabled"
			framework.getService("communication_layer").inject message
			events = framework.getService("events")
			spy = sinon.spy(events.emitter,"emit")
			setTimeout ->
				module.getPlace place.id,(err,place)->
					events.emitter.emit.restore()
					expect(err).to.be.null
					expect_message = sinon.match
						status:"disabled"
						name:place.name
					expect(spy.withArgs("place:update",place.id,expect_message).calledOnce).to.be.true
					done()
			,300

	describe.skip 'Place rename',->
		place = null

		before (done)->
			id = module.createPlaceId("share",null,null).place_id
			module.addPlace {
				id:id
				name:"test__"+new Date
				type:"share"
				owner_uid:null
				status:module.status.validated
			},{wait_validation:true},(err,_place)->
				expect(err).to.be.null
				expect(_place).to.be.an("object")
				place = _place
				done()

		after (done)->
			module.deletePlaceById place.id,(err,deleted)->
				done()

		it 'should check if the place name already exists and return an error if yes',(done)->
			id = module.createPlaceId("share",null,null).place_id
			module.addPlace {
				id:id
				name:"test__"+new Date+1
				type:"share"
				owner_uid:null
				status:module.status.validated
			},{wait_validation:true},(err,_place)->
				expect(err).to.be.null
				expect(_place).to.be.an("object")
				module.renamePlace place.id,{new_name:_place.name},(err)->
					expect(err).to.not.be.null
					module.deletePlaceById _place.id,(err,deleted)->
						done()

		it 'should check if the place exists',(done)->
			module.renamePlace "11111",{new_name:"a new name"},(err)->
				expect(err).to.not.be.null
				done()

		it 'should notity the kernel about the rename',(done)->
			service = framework.getService("protocol.builder").place
			spy = sinon.spy(service,"renamePlace")
			options =
				new_name:"random"+(+new Date)
			module.renamePlace place.id,options,(err)->
				service.renamePlace.restore()
				expect(spy.calledOnce).to.be.true
				done()

		it 'should rename it into the database',(done)->
			options =
				new_name:"random2"+(+new Date)
			module.renamePlace place.id,options,(err)->
				expect(err).to.be.null
				module.getPlace place.id,(err,p)->
					expect(p.name).to.be.equal(options.new_name)
					done()

		it 'should rename the content when receiving the correct network message and emit an event',(done)->
			message = 
				message_id:"111111"
				protocol:"place"
				method:"RENAME"
				date:+new Date
				src:"ansamb"
				dst:"ansamb"
				spl:place.id
				dpl:place.id
				data:
					name:"random3"+(+new Date)
			events = framework.getService("events")
			spy1 = sinon.spy(module,"renamePlace")
			spy2 = sinon.spy(events.emitter,"emit")
			framework.getService("communication_layer").inject message
			setTimeout ->
				module.renamePlace.restore()
				events.emitter.emit.restore()
				expect(spy1.withArgs(place.id,sinon.match({new_name:message.data.name,emit_network:false})).calledOnce).to.be.true
				expect(spy2.withArgs("place:update",place.id,sinon.match({name:message.data.name})).calledOnce).to.be.true
				done()
			,200

		it 'should create a notification',(done)->
			notification_manager = framework.getService("notification_manager")
			spy = sinon.spy(notification_manager,"createNotification")
			module.getPlace place.id,(err,p)->
				expect(err).to.be.null
				place = p
				old_name = p.name
				new_name = "random4"+(+new Date)
				module.renamePlace place.id,{new_name:new_name,emit_network:false},(err)->
					notification_manager.createNotification.restore()
					expect(err).to.be.null
					data = sinon.match
						old_name:old_name
						new_name:new_name
					expect(spy.withArgs(place.id,place.id,data).calledOnce).to.be.true
					done()

	describe 'Place leave',->
		@timeout(4000)
		
		uid = 'ansamb_test'
		place = null

		before (done)->
			contact_lib = framework.getService('api.contact')
			# we first need to create the contact because the place owner have to be an existing contact
			contact_lib.addContact {
				uid:uid
				firstname:"my firstname"
				lastname:"my lastname"
			},(err,contact)->
				expect(err).to.be.null
				expect(contact).to.be.an('object')
				id = module.createPlaceId("share",null,uid).place_id
				module.addPlace {
					id:id
					name:"test__"+new Date
					type:"share"
					owner_uid:uid
					status:module.status.pending
				},{wait_validation:false},(err,_place)->
					expect(err).to.be.null
					expect(_place).to.be.an("object")
					place = _place
					done()

		after (done)->
			contact_lib = framework.getService('api.contact')
			contact_lib.removeContactByUid uid,{emit_network:false},->
				module._deletePlaceFromDatabase place.id,(err,deleted)->
					done()

		it 'should emit a network message when leaving a place',(done)->
			protocol_builder = framework.getService("protocol.builder")
			spy = sinon.spy(protocol_builder.place,'leavePlace')
			module.deletePlaceById place.id,(err,deleted)->
				protocol_builder.place.leavePlace.restore()
				expect(spy.withArgs(sinon.match({place:place.id})).calledOnce).to.be.true
				done()
