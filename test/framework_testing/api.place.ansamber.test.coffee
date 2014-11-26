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
async = require 'async'

application_database = null
models = null
framework = null
#those tests assume that a place named "mocha_test exists"
place_name = "mocha_test"+new Date()
place_id = null
uid = "test"+new Date()
describe 'ANSAMBER',->
	before (done)->
		@timeout(5000)
		core = require process.cwd()
		core.defer.promise.then (_framework)->
			framework = _framework
			dbmanager = framework.getService("database_manager")
			application_database = dbmanager.getApplicationDatabase (err,db)->
				application_database = db
				models = application_database.models.global

				#we need to get the account before creating any place
				framework.getService("api.account").getAccount ->
					#create test place
					place_id = framework.getService("api.place").createPlaceId("share",null,null).place_id
					framework.getService("api.place").addPlace {
						id:place_id
						name:place_name
						type:"share"
						owner_uid:null
					},{wait_validation:true},(err,_place)->
						expect(err).to.be.null
						expect(_place).to.be.an("object")
						place = _place
						done()
	after (done)->
		framework.getService("api.place").deletePlaceById place_id,(err,deleted)->
			done()
	describe "api.place.ansamber lib",->
		module = null
		before (done)->
			@timeout(3000)
			module = framework.getService("api.place.ansamber")
			framework.getService("api.place").getPlaceFromName place_name,(err,place)->
				expect(err).to.be.null
				expect(place).to.be.an("object")
				place_id = place.id
				done()

		describe 'ansamber remove',->
			before (done)->
				module.removeAnsamberFromPlace place_id,uid,{emit_network:false},->
					done()
			it 'should remove the ansamber from the database',(done)->
				module._addAnsamber place_id,uid,{status:module.status.accepted},(err,ansamber)->
					expect(err).to.be.null
					expect(ansamber).to.be.an.object
					module.removeAnsamberFromPlace place_id,ansamber.uid,{emit_network:false},(err)->
						expect(err).to.be.null
						module.getAnsambersOfPlace place_id,(err,ansambers)->
							expect(err).to.be.null
							expect(_.findWhere(ansambers,{uid:ansamber.uid})).to.be.undefined
							done()

			it 'should return an error if the ansamber to delete not exists',(done)->
				module.removeAnsamberFromPlace place_id,uid,(err)->
					expect(err).to.be.equal("ansamber not found")
					done()

			it 'should return an error if the place the ansamber belongs to not exists',(done)->
				module._addAnsamber place_id,uid,{status:module.status.accepted},(err,ansamber)->
					module.removeAnsamberFromPlace "fake_place_id",uid,{emit_network:false},(err)->
						expect(err).to.be.equal("ansamber not found")
						module.removeAnsamberFromPlace place_id,uid,{emit_network:false},(err)->
							done()
			#Kernel send no response
			it.skip 'should send a network message if the emit_network is set to true and don\'t emit event',(done)->
				com_layer = framework.getService("communication_layer")
				spy = sinon.spy(com_layer,"send")
				event_emitter = framework.getService("events").emitter
				spy2 = sinon.spy(event_emitter,"emit")
				module._addAnsamber place_id,uid,{status:module.status.accepted},(err,ansamber)->
					expect(err).to.be.null
					module.removeAnsamberFromPlace place_id,uid,{emit_network:true},->				
						com_layer.send.restore()
						event_emitter.emit.restore()
						expect_message = sinon.match
							protocol:"place"
							method:"REMOVE_ANSAMBER"
							dpl:place_id
							data:
								uid:uid
						expect(spy.withArgs(expect_message).calledOnce).to.be.true
						expect(spy2.neverCalledWith("ansamber:remove")).to.be.true
						done()
			it 'should emit an event trough the events lib if the emit_network is set to false and no network message',(done)->
				event_emitter = framework.getService("events").emitter
				spy = sinon.spy(event_emitter,"emit")
				com_layer = framework.getService("communication_layer")
				spy2 = sinon.spy(com_layer,"send")
				module._addAnsamber place_id,uid,{status:module.status.accepted},(err,ansamber)->
					expect(err).to.be.null
					module.removeAnsamberFromPlace place_id,uid,{emit_network:false},->
						event_emitter.emit.restore()
						com_layer.send.restore()
						expect(spy2.callCount).to.be.equal(0)
						expect(spy.withArgs("ansamber:remove",place_id,uid).calledOnce).to.be.true
						done()
			it 'should call the remove method with emit_network set to false when receiving a network message',(done)->
				com_layer = framework.getService("communication_layer")
				message =
					message_id:"11111"
					protocol:"place"
					method:"REMOVE_ANSAMBER"
					spl:place_id
					dpl:place_id
					data:
						uid:uid
				spy = sinon.spy(module,"removeAnsamberFromPlace")
				com_layer = framework.getService("communication_layer")
				spy2 = sinon.spy(com_layer,"send")
				module._addAnsamber place_id,uid,{status:module.status.accepted},(err,ansamber)->
					expect(err).to.be.null
					com_layer.inject message
					setTimeout ->
						module.removeAnsamberFromPlace.restore()
						com_layer.send.restore()

						expect(spy.withArgs(place_id,uid,sinon.match({emit_network:false})).calledOnce).to.be.true
						expect(spy2.neverCalledWith(sinon.match({method:"REMOVE_ANSAMBER"}))).to.be.true

						done()
					,200
			it 'should add aliases and return the added aliases',(done)->
				uid = +new Date
				ansamber =
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
					place_id:place_id
				aliases1= [
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					}
				]
				aliases2= [
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:false
					},
					{
						alias:"myemail@emailbox.com"
						type:"email"
						default_alias:false
					},
					{
						alias:"myemail2@me.com"
						type:"email"
						default_alias:false
					},
					{
						alias:"39860327134"
						type:"tel"
						default_alias:false
					}
				]
				t= null
				async.waterfall [
					(callback)->
						application_database.sequelize.transaction (_t)->
							callback null,_t
					(_t,callback)->
						t= _t
						models.ansamber.__places__.addAnsamber(ansamber,aliases1,{transaction:t}).done callback
					(ansamber,callback)->
						module.addAliasesToAnsamber ansamber.id,aliases2,{transaction:t,raw:true},callback
					(results,callback)->
						expect(results.length).to.be.eql(3)
						models.ansamber_alias.count({transaction:t}).done callback
				],(err,count)->
					expect(err).to.be.null
					expect(count).to.be.eql(4)
					t.rollback().done done
	describe 'ansamber database models',->
		module = null
		before ->
			@timeout(3000)
			module = framework.getService("database_manager")

		transaction = null

		beforeEach (done)->
			application_database.sequelize.transaction {autocommit:false,isolationLevel:'SERIALIZABLE'},(t)->
				transaction= t
				done()

		afterEach (done)->
			transaction.rollback().done ()->
				done()

		it 'should have all required tables (models)',->
			expect(models).to.contain.keys(["ansamber","ansamber_alias","place"])

		#create and retrieve ansambers (with default alias) for a place
		it 'should create an ansamber into the database',(done)->
			ansamber_data =
				uid:"uid01"
				place_id:place_id
				firstname:"ff"
				lastname:"ll"
				status:"validated"
				request_id:"1111"
				admin:true
			models.ansamber.__places__.addAnsamber(ansamber_data,[],{transaction:transaction}).done (err,ansamber)->
				expect(err).to.be.null
				models.ansamber.find({where:{uid:"uid01",place_id:place_id}},{raw:true,transaction:transaction}).done (err,model)->
					expect(err).to.be.null
					expect(model.uid).to.be.equal("uid01")
					done()


		it 'should create ansamber with multiple aliases',(done)->
			ansamber_data =
				uid:"uid01"
				place_id:place_id
				firstname:"ff"
				lastname:"ll"
				status:"validated"
				request_id:"1111"
				admin:true
			async.waterfall [
				(callback)->
					models.ansamber.__places__.addAnsamber(ansamber_data,[
						{default_alias:true,alias:'test@ansamb.com',type:"email"},
						{default_alias:false,alias:'0693456781',type:"tel"},
						{default_alias:false,alias:'0693091263',type:"tel"}
					],{transaction:transaction,raw:true}).done callback
				(ansamber,callback)->
					models.ansamber_alias.count({where:{ansamber_id:ansamber.id},transaction:transaction}).done callback
				],(err,count)->
					expect(err).to.be.null
					expect(count).to.be.equal(3)
					done()

		it 'should remove all aliases of an ansamber when the ansamber is deleted',(done)->
			ansamber = 
				data:
					uid:+new Date
					firstname:'test'
					lastname:'test'
					status:"validated"
					place_id:place_id
				aliases:[
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					},
					{
						alias:"1111111"
						type:"tel"
					}
				]
			async.waterfall [
				(callback)->
					models.ansamber.__places__.addAnsamber(ansamber.data,ansamber.aliases,{transaction:transaction}).done callback
				(ansamber,callback)->
					expect(ansamber).to.not.be.null
					ansamber.destroy({transaction:transaction}).done callback
				(__,callback)->
					models.ansamber_alias.count({transaction:transaction}).done callback
			],(err,count)->
				console.log err
				expect(err).to.be.null
				expect(count).to.eql(0)
				done()

		it 'should add an alias to an existing ansamber',(done)->
			ansamber = 
				data:
					uid:+new Date
					firstname:'test'
					lastname:'test'
					status:'validated'
					place_id:place_id
				aliases:[
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					}
				]
			async.waterfall [
				(callback)->
					models.ansamber.__places__.addAnsamber(ansamber.data,ansamber.aliases,{transaction:transaction}).done callback
				(ansamber,callback)->
					expect(ansamber).to.be.an('object').that.have.property('aliases')
					alias = models.ansamber_alias.build({alias:"anotheremail@me.com",type:"email"})
					ansamber.addAlias(alias,{transaction:transaction}).done (err)->
						callback err,ansamber.uid
				(uid,callback)->
					models.ansamber_alias.findAll({},{raw:true,transaction:transaction}).done callback
			],(err,aliases)->
				expect(err).to.be.null
				expect(aliases).to.have.length(2)
				done()

		it 'should delete the alias of an existing ansamber',(done)->
			ansamber = 
				data:
					uid:+new Date
					firstname:'test'
					lastname:'test'
					status:'validated'
					place_id:place_id
				aliases:[
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					},
					{
						alias:"myemail2@me.com"
						type:"email"
					}
				]
			async.waterfall [
				(callback)->
					models.ansamber.__places__.addAnsamber(ansamber.data,ansamber.aliases,{transaction:transaction}).done callback
				(ansamber,callback)->
					expect(ansamber).to.be.an('object')
					ansamber.getAliases({transaction:transaction}).done (err,aliases)->
						callback err,aliases,ansamber
				(aliases,ansamber,callback)->
					expect(aliases).to.have.length(2)
					aliases[0].destroy({transaction:transaction}).done (err)->
						callback err,ansamber
				(ansamber,callback)->
					ansamber.getAliases({transaction:transaction}).done callback
			],(err,aliases)->
				expect(err).to.be.null
				expect(aliases).to.have.length(1)
				done()

		it 'should get ansamber with alias from place id',(done)->
			ansamber=
				data:
					uid:+new Date
					firstname:'test'
					lastname:'test'
					status:'validated'
					place_id:place_id
				aliases:[
					{
						alias:"myemail2@me.com"
						type:"email"
					}
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					},
					{
						alias:"1111111"
						type:"tel"
					}
				]

			async.waterfall [
				(callback)->
					models.ansamber.__places__.addAnsamber(ansamber.data,ansamber.aliases,{transaction:transaction}).done callback
				(ansamber,callback)->
					models.ansamber.__places__.getAnsambersForPlace(place_id,{transaction:transaction,raw:true}).done callback
			],(err,models)->
				expect(err).to.be.null
				expect(models[0].aliases).to.be.not.null
				expect(models[0].aliases.alias).to.be.equal("myemail@me.com")
				done()

		it 'should get a place with all ansambers',(done)->
			ansamber=
				data:
					uid:+new Date
					firstname:'test'
					lastname:'test'
					status:'validated'
					place_id:place_id
				aliases:[
					{
						alias:"myemail2@me.com"
						type:"email"
					}
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					},
					{
						alias:"1111111"
						type:"tel"
					}
				]
			ansamber2= JSON.parse(JSON.stringify(ansamber))
			ansamber2.data.uid = ansamber.data.uid + "test"
			async.waterfall [
				(callback)->
					models.ansamber.__places__.addAnsamber(ansamber.data,ansamber.aliases,{transaction:transaction}).done callback
				(__,callback)->
					models.ansamber.__places__.addAnsamber(ansamber2.data,ansamber2.aliases,{transaction:transaction}).done callback
				(__,callback)->
					models.place.__places__.getByid(place_id,{transaction:transaction,raw:false}).done callback
				],(err,place)->
					expect(err).to.be.null
					expect(place).to.be.an('object')
					expect(place.ansambers).to.have.length(2)
					done()
		it 'should trigger an error when trying to add a duplicate alias to an ansamber',(done)->
			ansamber=
				data:
					uid:+new Date
					firstname:'test'
					lastname:'test'
					status:'validated'
					place_id:place_id
				aliases:[
					{
						alias:"myemail2@me.com"
						type:"email"
					},
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					},
					{
						alias:"1111111"
						type:"tel"
					}
				]
			ansamber2= JSON.parse(JSON.stringify(ansamber))
			async.waterfall [
				(callback)->
					models.ansamber.__places__.addAnsamber(ansamber.data,ansamber.aliases,{transaction:transaction}).done callback
				(__,callback)->
					models.ansamber_alias.create(ansamber.aliases[0],{transaction:transaction}).done callback
			],(err,alias)->
				expect(err).to.be.not.null
				expect(alias).to.be.null
				expect(err).to.have.property('errno',19)
				expect(err).to.have.property('code','SQLITE_CONSTRAINT')
				done()
		it 'should trigger an error when trying to add an alias to an unexinsting contact',(done)->
			uid = +new Date
			alias=
				contact_uid : uid
				alias:"myemail@me.com"
				type:"email"
				default_alias:true
			async.waterfall [
				(callback)->
					models.ansamber_alias.create(alias,{transaction:transaction}).done callback
			],(err,alias)->
				expect(err).to.be.not.null
				expect(err).to.have.property('errno',19)
				expect(err).to.have.property('code','SQLITE_CONSTRAINT')
				expect(alias).to.be.null
				done()
		it 'should add aliases to an ansamber without triggering error if it already exist',(done)->
				uid = +new Date
				ansamber=
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
					place_id:place_id
				aliases1= [
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					},
					{
						alias:"myemail2@me.com"
						type:"email"
						default_alias:false
					},
					{
						alias:"262693450982"
						type:"tel"
						default_alias:false
					}
				]
				aliases2= [
					{
						alias:"myemail@emailbox.com"
						type:"email"
						default_alias:false
					},
					{
						alias:"myemail2@me.com"
						type:"email"
						default_alias:false
					},
					{
						alias:"39860327134"
						type:"tel"
						default_alias:false
					}
				]
				async.waterfall [
					(callback)->
						models.ansamber.__places__.addAnsamber(ansamber,aliases1,{transaction:transaction}).done callback
					(__,callback)->
						models.ansamber.find({where:{uid:uid,place_id:place_id}},{transaction:transaction,raw:true}).done callback
					(ansamber,callback)->
						models.ansamber_alias.__places__.addAliases(ansamber.id,aliases2,{transaction:transaction}).done callback
					(__,callback)->
						models.ansamber_alias.count({transaction:transaction}).done callback
				],(err,count)->
					expect(err).to.be.null
					expect(count).to.be.eql(5)
					done()

