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
_ = require 'underscore'
fs = require 'fs'
path = require 'path'
utils = require './utils/utils'
{EventEmitter}   = require('events')
migrationUtils = require './utils/migrationUtils'

class MigrationManager extends EventEmitter
	constructor:(@Sequelize_instance,@db_version,@app_version,@migration_dir)->
	isMigrationRequired:->
		dv = @vToN @db_version
		av = @vToN @app_version
		unless dv? or av?
			return throw new Error("Bad version format")
		return dv<av
	run:->
		if not @isMigrationRequired()
			@emit 'end',null,@app_version,false
			return true
		migrator = @Sequelize_instance?.getMigrator()
		unless migrator?
			error = "unable to get a migrator instance"
			return @emit 'end',error,null,false
		current_version = @db_version
		migrationFiles = migrationUtils.getListMigrationFiles @migration_dir
		if migrationFiles==null or migrationFiles?.length==0
			error = "unable to list migration files"
			return @emit 'end',error,null,false
		first = migrationUtils.getMigrationFileFromVersion migrationFiles,@db_version
		(applyMigrationFile=(migrator,file)=>
			if file==null
				return @emit 'end','missing migration file',current_version,false
			migrator.exec(path.join(@migration_dir,file)).done (err)=>
				if err?
					return @emit 'end',err,current_version,false
				current_version = migrationUtils.parseFileName(file).to
				if current_version == @app_version
					return @emit 'end',err,current_version,true
				next = migrationUtils.getMigrationFileFromVersion migrationFiles,current_version
				applyMigrationFile.call @,migrator,next
		).call(@,migrator,first)
		@
	vToN:(version)->
		#in this case, we fix the digit number to 2
		utils.versionToNumber.call null,version,2

exports = module.exports = MigrationManager