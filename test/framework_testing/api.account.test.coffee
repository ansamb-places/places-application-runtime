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

framework = null
module = null

describe 'api.account lib',->
	
	before (done)->
		@timeout(5000)
		core = require process.cwd()
		core.defer.promise.then (_framework)->
			framework = _framework
			module = framework.getService("api.account")
			done()

	describe 'REGISTER',->

		it 'should return an error if alias_options are not defined or are incomplete',(done)->
			module.register {firstname:"test",email:"test@test.org"},(err,detail)->
				expect(err).to.be.equal("Alias options are missing")
				module.register {firstname:"test",email:"test@test.org"},{type:"email"},(err,detail)->
					expect(err).to.be.equal("Alias options are missing")
					done()

		it 'should return an error if alias_options\' field_name is not a string or not exists into data',(done)->
			module.register {firstname:"test",email:"test@test.org"},{field_name:1,type:"email"},(err,detail)->
				expect(err).to.be.equal("Wrong alias")
				module.register {firstname:"test",email:"test@test.org"},{field_name:"test",type:"email"},(err,detail)->
					expect(err).to.be.equal("Wrong alias")
					done()

		it 'should return an error if some fields are missing into the register request',(done)->
			module.register {firstname:"test",email:"test@test.org"},{field_name:"email",type:"email"},(err,detail)->
				expect(err).to.be.equal("Invalid JSON schema")
				done()


		it 'should send a network message if all required fields are filled',(done)->
			com_layer = framework.getService("communication_layer")
			spy = sinon.spy(com_layer,"send")
			request =
				firstname:"test"
				lastname:"test"
				email:"myemail@me.com"
				password:"mypassword"
			module.register request,{field_name:"email",type:"email"},(err,detail)->
				match = sinon.match
					protocol:"account"
					method:"REGISTER"
				expect(spy.withArgs(match).calledOnce).to.be.true
				com_layer.send.restore()
				done()

		it 'should propagate the error code and the error message to the callback',(done)->
			request =
				firstname:"test"
				lastname:"test"
				email:"myemail@me.com"
				password:"mypassword"
			fake_response =
				code:409
				data:
					msg:"The account already exists"
				desc:"Conflict"
			builder = framework.getService("protocol.builder").account
			originalRequest = builder.registerRequest

			stub = sinon.stub builder,"registerRequest",->
				net_obj = originalRequest.apply builder,arguments 
				fun= sinon.stub()
				fun.yields(null,fake_response)
				net_obj.send= fun
				return net_obj

			module.register request,{field_name:"email",type:"email"},(err,detail)->
				expect(detail).to.have.property('error_code',fake_response.code)
				expect(err.message).to.be.equal(fake_response.data.msg)
				builder.registerRequest.restore()
				done()

	describe 'RESEND_CODE',->

		it 'should return an error if the password is not valid',(done)->
			module.resend_code "",(err)->
				expect(err).to.be.equal("Invalid password")
				module.resend_code 1,(err)->
					expect(err).to.be.equal("Invalid password")
					done()

		it.skip 'should send a network message with the correct hashed password',(done)->
			##TODO REWRITE TEST TO WORK WITH EXTERNAL_SERVICE_MANAGER
			clear_password = 'mypassword'
			module.account =
				alias: 'myemail@me.com',
				alias_type: 'email',
				password:
					algo: 'sha256',
					salt_local: 'a5953a7f4fc8e567',
					salt_remote: '1a48f38c68eb9758',
					value_local: '0f194359bd927afe86224ead159cad9f7bbfea6d6e7b0f650405e412bef3341f',
					value_remote: '9acf7f4512fabdca30fc9d9986c300018a1d8c76078109a6f55f9d743dda6f2a',
				firstname: 'test',
				lastname: 'test'

			com_layer = framework.getService("communication_layer")
			spy = sinon.spy(com_layer,"send")

			module.resend_code clear_password,(err)->
				match = sinon.match
					protocol:"account"
					method:"RESEND_CODE"
					data:
						alias:module.account.alias
						alias_type:module.account.alias_type
						password:module.account.password.value_remote
				expect(spy.withArgs(match).calledOnce).to.be.true
				com_layer.send.restore()
				done()

		it.skip 'should get back a 404 error if the accout doesn\'t exist',(done)->
			##TODO REWRITE TEST TO WORK WITH EXTERNAL_SERVICE_MANAGER
			clear_password = 'mypassword'
			module.account =
				alias: "myemailpipo#{+new Date}@me.com",
				alias_type: 'email',
				password:
					algo: 'sha256',
					salt_local: 'a5953a7f4fc8e567',
					salt_remote: '1a48f38c68eb9758',
					value_local: '0f194359bd927afe86224ead159cad9f7bbfea6d6e7b0f650405e412bef3341f',
					value_remote: '9acf7f4512fabdca30fc9d9986c300018a1d8c76078109a6f55f9d743dda6f2a',
				firstname: 'test',
				lastname: 'test'

			module.resend_code clear_password,(err)->
				expect(err).to.be.equal("The registration request was not found")
				done()

	describe 'GEN_CRED',->
		it 'should send a network message with the correct service',(done)->
			service = 'voip'

			com_layer = framework.getService("communication_layer")
			spy = sinon.spy(com_layer,"send")

			module.generate_credential 'voip', (data)->
				match = sinon.match
					protocol:"account"
					method:"GEN_CRED"
					data:
						service:service
				expect(spy.withArgs(match).calledOnce).to.be.true
				com_layer.send.restore()
				done()

		it 'should callback on network answer message',(done)->
			service = 'voip'
			fake_ICE_data = [{url: 'stun:api.ansamb.com:3478'},{url: 'turn:api.ansamb.com:3478',username: 'test',password: 'test'}]
			fake_response =
				code:200
				data:fake_ICE_data
			builder = framework.getService("protocol.builder").account
			originalRequest = builder.generateCredentialRequest

			stub = sinon.stub builder,"generateCredentialRequest",->
				net_obj = originalRequest.apply builder,arguments 
				fun= sinon.stub()
				fun.yields(null,fake_response)
				net_obj.send= fun
				return net_obj

			module.generate_credential service,(err,reply)->
				expect(err).to.be.null
				expect(reply).to.be.equal(fake_ICE_data)
				builder.generateCredentialRequest.restore()
				done()

		it 'should return an array of credentials',(done)->
			service = 'voip'

			module.generate_credential 'voip', (err, reply)->
				expect(err).to.be.null
				expect(reply).to.be.an('array')
				done()
