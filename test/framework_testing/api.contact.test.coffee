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
async = require 'async'

application_database = null
models = null
framework = null
# those tests assume that a user named lm205 exists and is online
user_uuid = 'lm205'
user_state = 'online'

describe 'CONTACT',->
	before (done)->
		@timeout(4000)
		core = require process.cwd()
		console.log "test"
		core.defer.promise.then (_framework)->
			framework = _framework
			dbmanager = framework.getService("database_manager")
			application_database = dbmanager.getApplicationDatabase (err,db)->
				console.log "test"
				application_database = db
				models = application_database.models.global
				done()
	describe 'api.contact lib',->
		module = null
		before ->
			module = framework.getService("api.contact")

		it 'the test configuration should be ok',->
			expect(framework).to.be.an("object")

		it 'should correctly load the lib',->
			expect(module).to.be.an("object")

		it 'should emit a state event through the event service on STATE_PUBLISH published event',->
			events = framework.getService("events")
			spy = sinon.spy(events.emitter,"emit")
			contacts = {}
			contacts[user_uuid] = user_state
			framework.getService("communication_layer").inject {ver:1, protocol: 'contact', method: 'STATUS', data: contacts}
			expect(spy.withArgs("contact:status",contacts).calledOnce).to.be.true
			events.emitter.emit.restore()

		it 'should add aliases and return the added aliases',(done)->
			uid = +new Date
			contact =
				uid:uid
				firstname:"my firstname"
				lastname:"my lastname"
				request_id:"111111"
				status:"validated"
			aliases= [
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
					models.contact.__places__.addContact(contact,aliases,{transaction:t}).done callback
				(contact,callback)->
					module.addAliasesToContact uid,aliases2,{transaction:t,raw:true},callback
				(results,callback)->
					expect(results.length).to.be.eql(3)
					models.contact_alias.count({transaction:t}).done callback
			],(err,count)->
				expect(err).to.be.null
				expect(count).to.be.eql(4)
				t.rollback().done done
	describe 'contact database models',->
		framework = null
		module = null
		before ->
			@timeout(3000)
			module = framework.getService("database_manager")


		describe 'Contacts',->

			t = null

			beforeEach (done)->
				application_database.sequelize.transaction (_t)->
					t = _t
					done()

			afterEach (done)->
				t.rollback().done ->
					done()

			it 'database object should have all required tables (models)',->
				expect(models).to.contain.keys(['ansamber','contact','contact_alias'])

			it 'should create a contact and set the correct relations between tables',(done)->
				uid = +new Date
				contact =
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
				models.contact.__places__.addContact(contact,[],{transaction:t}).done (err,c)->
					expect(err).to.be.null
					models.contact.__places__.getContactByUid(uid,{raw:true,transaction:t}).done (err,contact)->
						expect(err).to.be.null
						expect(contact).to.not.be.null
						expect(contact).to.have.property('aliases',null)
						done()

			it 'should return all contact who are in my contact list (with alias contact data)',(done)->
				uid = +new Date
				contact =
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
				aliases= [
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					}
				]
				async.waterfall [
					(callback)->
						models.contact.__places__.addContact(contact,aliases,{transaction:t}).done callback
					(__,callback)->
						contact.uid=+10
						models.contact.__places__.addContact(contact,aliases,{transaction:t}).done callback
					(__,callback)->
						models.contact.count({transaction:t}).done (err,count)->
							expect(count).to.be.equal(2)
							callback null
					(callback)->
						models.contact.__places__.getApplicationContacts({options:{transaction:t,raw:true}}).done callback
				],(err,contacts)->
					expect(err).to.be.null
					expect(contacts).to.have.length(2)
					expect(contacts[0]).to.have.property('aliases')
					done()

			it 'should delete an alias without deleting the corresponding contact',(done)->
				uid = +new Date
				contact =
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
				aliases= [
					{
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					}
				]
				async.waterfall [
					(callback)->
						models.contact.count({transaction:t}).done (err,count)->
							return callback err if err?
							expect(count).to.eql(0)
							callback null
					(callback)->
						models.contact.__places__.addContact(contact,aliases,{transaction:t}).done callback
					(__,callback)->
						models.contact.__places__.getContactByUid(uid,{transaction:t}).done (err,contact)->
							return callback err if err?
							expect(contact).to.not.be.null
							callback null,contact
					(contact,callback)->
						models.contact_alias.destroy({alias:"myemail@me.com",type:"email",contact_uid:uid},{transaction:t}).done (err)->
							callback err
					(callback)->
						models.contact.count({transaction:t}).done (err,count)->
							return callback err if err?
							expect(count).to.eql(1)
							callback null
					(callback)->
						models.contact_alias.count({transaction:t}).done (err,count)->
							expect(count).to.eql(0)
							callback null
				],(err,contact)->
					expect(err).to.be.null
					done()

			it 'should be able to get/set the contact data trough the ORM object (status, request_id, ...)',(done)->
				uid = +new Date
				contact =
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
				async.waterfall [
					(callback)->
						models.contact.__places__.addContact(contact,[],{transaction:t}).done callback
					(contact,callback)->
						expect(contact.status).to.eql('validated')
						contact.updateAttributes({status:"pending"},{transaction:t}).done callback
					(modified_contact,callback)->
						models.contact.__places__.getContactByUid(uid,{raw:true,transaction:t}).done (err,c)->
							expect(c).to.have.property('status','pending')
							callback null
				],(err)->
					expect(err).to.be.null
					done()

			it 'should be able to retrieve contacts filtered by his status',(done)->
				uid = +new Date
				contact =
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
				uid2 = uid+10
				contact2 =
					uid:uid2
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"pending"
				async.waterfall [
					(callback)->
						models.contact.__places__.addContact(contact,[],{transaction:t}).done callback
					(__,callback)->
						models.contact.__places__.addContact(contact2,[],{transaction:t}).done callback
					(__,callback)->
						models.contact.count({transaction:t}).done (err,count)->
							expect(count).be.eql(2)
							callback null
					(callback)->
						where= {status:"pending"}
						options= {transaction:t,raw:true}
						models.contact.__places__.getApplicationContacts({where:where,options:options}).done callback
				],(err,contacts)->
					expect(err).to.be.null
					expect(contacts).to.have.length(1)
					expect(contacts[0]).to.have.property('status','pending')
					done()

			it 'should retrieve the contact with its default alias if any',(done)->
				uid = +new Date
				contact =
					aliases:[
						{
							alias:"myemail@me.com"
							type:"email"
							default_alias:true
						}
						{
							alias:"111111111"
							type:"tel"
						}
					]
					contact:
						request_id:"111111"
						status:"validated"
						uid:uid
						firstname:"my firstname"
						lastname:"my lastname"
				uid2 = uid+10
				contact2 =
					contact:
						uid:uid2
						firstname:"my firstname"
						lastname:"my lastname"
						request_id:"111111"
						status:"pending"
				async.waterfall [
					(callback)->
						models.contact.__places__.addContact(contact.contact,contact.aliases,{transaction:t}).done callback
					(__,callback)->
						models.contact.__places__.addContact(contact2.contact,[],{transaction:t}).done callback
					(__,callback)->
						models.contact.__places__.getApplicationContacts({options:{raw:true,transaction:t}}).done callback
				],(err,contacts)->
					expect(err).to.be.null
					expect(contacts[0].aliases).to.not.be.null
					expect(contacts[1].aliases).to.be.null
					done()

			it 'should add an alias to an existing contact',(done)->
				uid = +new Date
				contact=
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
				alias= [
					{
						contact_uid:uid
						alias:"myemail@me.com"
						type:"email"
						default_alias:true
					},
					{
						contact_uid:uid
						alias:"myemail2@me.com"
						type:"email"
						default_alias:false
					}
				]
				async.waterfall [
					(callback)->
						models.contact_alias.count({transaction:t}).done callback
					(count,callback)->
						expect(count).to.be.eql(0)
						models.contact.__places__.addContact(contact,[],{transaction:t}).done callback
					(__,callback)->
						models.contact_alias.create(alias[0],{transaction:t}).done callback
					(__,callback)->
						models.contact_alias.create(alias[1],{transaction:t}).done callback
					(__,callback)->
						models.contact_alias.count({transaction:t}).done callback
				],(err,count)->
					expect(err).to.be.null
					expect(count).to.be.eql(2)
					done()
			it 'should delete all contact_alias of the contact when he is deleted',(done)->
				uid = +new Date
				contact1=
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
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
				contact2=
					uid:uid+10
					firstname:"my firstname2"
					lastname:"my lastname2"
					request_id:"111112"
					status:"validated"
				aliases2= [
					{
						alias:"email@me.com"
						type:"email"
						default_alias:true
					},
					{
						alias:"email2@me.com"
						type:"email"
						default_alias:false
					},
					{
						alias:"262693450986"
						type:"tel"
						default_alias:false
					}
				]
				async.waterfall [
					(callback)->
						models.contact_alias.count({transaction:t}).done callback
					(count,callback)->
						expect(count).to.be.eql(0)
						models.contact.__places__.addContact(contact1,aliases1,{transaction:t}).done callback
					(contact,callback)->
						models.contact.__places__.addContact(contact2,aliases2,{transaction:t}).done callback
					(__,callback)->
						models.contact_alias.count({transaction:t}).done callback
					(count,callback)->
						expect(count).to.be.eql(6)
						models.contact.destroy({uid:uid},{transaction:t}).done callback
					(__,callback)->
						models.contact.count({transaction:t}).done callback
					(count,callback)->
						expect(count).to.be.eql(1)
						models.contact_alias.count({transaction:t}).done callback
				],(err,count)->
					expect(err).to.be.null
					expect(count).to.be.eql(3)
					done()
			it 'should trigger an error when trying to add an already existing alias to a contact',(done)->
				uid = +new Date
				contact1=
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
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
				async.waterfall [
					(callback)->
						models.contact.__places__.addContact(contact1,aliases1,{transaction:t}).done callback
					(count,callback)->
						models.contact_alias.create(aliases1[2],{transaction:t}).done callback
				],(err,alias)->
					expect(err).to.be.not.null
					expect(err).to.have.property('errno',19)
					expect(err).to.have.property('code','SQLITE_CONSTRAINT')
					expect(alias).to.be.null
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
						models.contact_alias.create(alias,{transaction:t}).done callback
				],(err,alias)->
					expect(err).to.be.not.null
					expect(err).to.have.property('errno',19)
					expect(err).to.have.property('code','SQLITE_CONSTRAINT')
					expect(alias).to.be.null
					done()
			it 'should add aliases to a contact without triggering error if it already exist',(done)->
				uid = +new Date
				contact1=
					uid:uid
					firstname:"my firstname"
					lastname:"my lastname"
					request_id:"111111"
					status:"validated"
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
						models.contact.__places__.addContact(contact1,aliases1,{transaction:t}).done callback
					(__,callback)->
						models.contact_alias.__places__.addAliases(uid,aliases2,{transaction:t}).done callback
					(__,callback)->
						models.contact_alias.count({transaction:t}).done callback
				],(err,count)->
					expect(err).to.be.null
					expect(count).to.be.eql(5)
					done()
