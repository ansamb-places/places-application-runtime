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
proxyquire = require 'proxyquire'
module = require process.cwd()+'/lib/utils/utils'

fake_migration_file1 = "20140603164100-migration-from-1.2.1-to-1.2.2.js"
fake_migration_file2 = "20140603164100-migration-from-1.2.2-to-1.2.3.js"

migrationUtilModule = proxyquire process.cwd()+'/lib/utils/migrationUtils',
	fs:{readdirSync:->["test.js",".git","migration-from-1.2.2-to-1.2.3.js",fake_migration_file1,fake_migration_file2]}

describe 'Utils lib',->
	describe 'version to number',->
		
		it 'should convert a version string into a number',->
			result = module.versionToNumber	"3.4.5",2
			expect(result).to.be.a("number")

		it 'shoud compare two versions correctly',->
			v1 = module.versionToNumber "0.0.1",3
			v2 = module.versionToNumber "0.0.3",3
			v3 = module.versionToNumber "0.1.3",3
			v4 = module.versionToNumber "0.1.4",3
			v5 = module.versionToNumber "1.0.4",3
			v6 = module.versionToNumber "1.0.10",3
			v7 = module.versionToNumber "1.2.4",3
			v8 = module.versionToNumber "1.0.10",3
			expect(v1<v2).to.be.true
			expect(v3<v4).to.be.true
			expect(v5<v6).to.be.true
			expect(v7>v8).to.be.true

		it 'should return null if the version if malformed',->
			expect(module.versionToNumber "233.a.0",2).to.be.null

	describe 'string',->
		
		it 'should replace whitespace by an underscore',->
			expect(module.normalized_string "this is a test_").to.be.equal("this_is_a_test_")

	describe 'migration fs lib',->
		it 'should correctly parse a migration file name',->
			parsed = migrationUtilModule.parseFileName fake_migration_file1
			expect(parsed).to.have.property('from','1.2.1')
			expect(parsed).to.have.property('to','1.2.2')

		it 'should list only files which are migration files',->
			files = migrationUtilModule.getListMigrationFiles()
			expect(files).to.be.an('array')
			expect(files.length).to.be.equal(2)
			expect(files[0]).to.be.equal(fake_migration_file1)
			expect(files[1]).to.be.equal(fake_migration_file2)

		it 'should be able to get a migration file from a given version if the file exists',->
			files = migrationUtilModule.getListMigrationFiles()
			file = migrationUtilModule.getMigrationFileFromVersion files,"1.2.2"
			expect(file).to.be.equal(fake_migration_file2)

		it 'should return null if no file match the given version',->
			files = migrationUtilModule.getListMigrationFiles()
			file = migrationUtilModule.getMigrationFileFromVersion files,"1.2.5"
			expect(file).to.be.null
