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

migrationUtils = require process.cwd()+"/lib/utils/migrationUtils"
module = null

# test fake object set up
fake_list = [
	"20140603164100-migration-from-1.2.1-to-1.2.2.js"
	"20140603164100-migration-from-1.2.2-to-1.2.3.js"
]
migrator = {
	exec:(path)->
		return
}

describe 'Migration Manager lib',->
	getListMigrationFiles = null
	
	before ->
		getListMigrationFiles = sinon.stub(migrationUtils,"getListMigrationFiles")
		getListMigrationFiles.returns(fake_list)
		module = proxyquire process.cwd()+"/lib/MigrationManager",
			migrationUtils:migrationUtils
		
	after ->
		getListMigrationFiles.restore()
	
	it 'should detect if a migration is required depending on versions',->
		migrationManager = new module null,"0.0.2","0.0.3","migration_dir"
		expect(migrationManager.isMigrationRequired()).to.be.true
		
		migrationManager = new module null,"0.0.2","0.0.2","migration_dir"
		expect(migrationManager.isMigrationRequired()).to.be.false

	it 'should raise an error if versions are malformed',->
		migrationManager = new module null,"0.0.2","0.0.a","migration_dir"
		expect(migrationManager.isMigrationRequired).to.throw(Error)

	it 'should immediately end the migration process if no migration is required',(done)->
		migrationManager = new module null,"0.0.2","0.0.2","migration_dir"
		migrationManager.on 'end',(error,version,migrated)->
			expect(error).to.be.null
			expect(version).to.be.equal("0.0.2")
			expect(migrated).to.be.false
			done()
		migrationManager.run()

	it 'should return an error if no valid migrator has been defined',(done)->
		migrationManager = new module null,"0.0.2","0.0.3","migration_dir"
		migrationManager.on 'end',(error,version,migrated)->
			expect(error).not.be.null
			expect(migrated).to.be.false
			done()
		migrationManager.run()

	it 'should run migration files to reach the newer bdd version',(done)->
		mock = sinon.mock(migrator)
		mock.expects("exec").twice().returns {done:(cb)->cb(null)}

		migrationManager = new module {getMigrator:->migrator},"1.2.1","1.2.3","migration_dir"		
		expect(migrationManager.isMigrationRequired()).to.be.true
		migrationManager.on 'end',(error,final_version,migrated)->
			expect(error).to.be.null
			expect(migrated).to.be.true
			expect(final_version).to.be.equal("1.2.3")
			mock.verify()
			mock.restore()
			done()
		migrationManager.run()

	it 'should return an error if a migration file is missing',(done)->
		mock = sinon.mock(migrator)
		mock.expects("exec").atLeast(2).returns {done:(cb)->cb(null)}

		migrationManager = new module {getMigrator:->migrator},"1.2.1","1.2.4","migration_dir"		
		expect(migrationManager.isMigrationRequired()).to.be.true
		migrationManager.on 'end',(error,final_version,migrated)->
			expect(error).to.not.be.null
			expect(migrated).to.be.false
			expect(final_version).to.be.equal("1.2.3")
			mock.verify()
			mock.restore()
			done()
		migrationManager.run()