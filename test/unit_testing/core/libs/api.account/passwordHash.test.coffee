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

module = require path.join(env.base_path,"api.account","passwordHash")

describe 'Password Hash Module',->

	it 'should correctly generate a salt synchronously',->
		expect(module.generateSaltSync()).to.be.a("string").that.have.length.of.at.least(1)

	it 'should correctly generate a salt asynchronously',(done)->
		module.generateSalt (salt)->
			expect(salt).to.be.a("string").that.have.length.of.at.least(1)
			done()

	it 'should generate a salt with a given length',->
		expect(module.generateSaltSync(12)).to.be.a("string").that.have.length.of.at.least(12)

	it 'should return the hashed of the password even if the salt is missing',->
		clear_password = "my_password"
		cipher = module.hashPassword(clear_password)
		expect(cipher).to.not.be.equal(clear_password)
		expect(cipher).to.have.length(64)
		cipher = module.hashPassword(clear_password,"testok?")
		expect(cipher).to.not.be.equal(clear_password)
		expect(cipher).to.have.length(64)

	it 'should give different value of the hashed password if the salt differ',->
		clear_password = "my_super_password"
		cipher = module.hashPassword(clear_password,"salt1")
		cipher2 = module.hashPassword(clear_password,"salt2")
		expect(cipher).to.not.equal(cipher2)

	it 'should return an hashed password with a random salt synchronously',->
		clear_password = "drowssap"
		cipher_obj = module.generateSaltAndHashPasswordSync(clear_password)
		cipher2_obj = module.generateSaltAndHashPasswordSync(clear_password)
		expect(cipher_obj).to.be.an('object').that.have.keys('algo','value','salt')
		expect(cipher2_obj).to.be.an('object').that.have.keys('algo','value','salt')
		# make sure the salt and hashed passwords are different
		expect(cipher_obj.salt).to.not.be.equal(cipher2_obj.salt)
		expect(cipher_obj.value).to.not.be.equal(cipher2_obj.value)

	it 'should return an hashed password with a random salt asynchronously',->
		clear_password = "drowssap"
		module.generateSaltAndHashPassword clear_password,(cipher_obj)->
			module.generateSaltAndHashPassword clear_password,(cipher2_obj)->
				expect(cipher_obj).to.be.an('object').that.have.keys('algo','value','salt')
				expect(cipher2_obj).to.be.an('object').that.have.keys('algo','value','salt')
				# make sure the salt and hashed passwords are different
				expect(cipher_obj.salt).to.not.be.null
				expect(cipher2_obj.salt).to.not.be.null
				expect(cipher_obj.salt).to.not.be.equal(cipher2_obj.salt)
				expect(cipher_obj.value).to.not.be.equal(cipher2_obj.value)
