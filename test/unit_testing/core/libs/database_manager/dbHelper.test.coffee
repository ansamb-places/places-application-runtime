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
fs = require 'fs'
path = require 'path'
Sequelize = require 'sequelize'

module = require process.cwd()+"/core/libs/database_manager/dbHelper"
tmp_folder = __dirname
tmp_dir = "__test__db_helper"
p = path.join tmp_folder,tmp_dir
db_path = path.join p,"db1.sqlite"

describe 'database helper module',->
	
	before ->
		try
			fs.mkdirSync p
		catch e
	
	after ->
		try
			fs.rmdirSync p
		catch e

	it 'should return null if the db file not exists and create option not set',->
		sequelize_instance = module.getSqliteInstance db_path

		expect(sequelize_instance).to.be.null

	it 'should return a valid instance if db file not exists but create option set to true',->
		res = module.getSqliteInstance db_path,{create:true}

		expect(res).to.not.be.null
		expect(res.created).to.be.true
		expect(res.sequelize).to.be.an.instanceOf(Sequelize)

	it 'should cache the database instance if the same path is used multiple time',->
		res = module.getSqliteInstance db_path,{create:true}
		res2 = module.getSqliteInstance db_path
		
		expect(res).to.deep.equal(res2)

	it 'should delete the db file when calling deleteSqliteInstance',(done)->
		fs.writeFileSync(db_path,"")
		module.deleteSqliteInstance db_path,(err)->
			exists = fs.existsSync(db_path)
			fs.unlinkSync(db_path) if exists
			expect(err).to.be.null
			expect(exists).to.be.false
			done()

	it 'should delete the sequelize instance from the cache when calling deleteSqliteInstance',->
		fs.writeFileSync(db_path,"")
		module.getSqliteInstance db_path #create an entry into the cache
		res = module.getSqliteInstance db_path #get the cached instance
		module.deleteSqliteInstance db_path,(err)->
			fs.unlinkSync(db_path) if fs.existsSync(db_path)
			
			res2 = module.getSqliteInstance db_path

			expect(err).to.be.null
			expect(res).to.not.be.null
			expect(res2).to.be.null
			
