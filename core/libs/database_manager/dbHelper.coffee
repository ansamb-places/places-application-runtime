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
Sequelize = require 'sequelize'
_ = require 'underscore'
fs = require 'fs'
_path = require 'path'
rimraf = require 'rimraf'
instances = {}

exports.deleteSqliteInstance = (path,cb)->
	try
		instances[path]?.sequelize?.connectorManager?.database?.close()
		# use rimraf to delete the place database file to deal with EBUSY errors on windows
		rimraf sanitizeDbName(path),(err)->
			if instances.hasOwnProperty(path)
				delete instances[path]
			cb err
	catch e
		console.error(e)
		cb e
sanitizeDbName = (p)->
	db_name = _path.basename(p).replace(/:/g,"_")
	return _path.join(_path.dirname(p),db_name)

exports.getSqliteInstance = (path,options)->
	options = _.extend {
		create:false
	},options
	real_path = sanitizeDbName(path)
	unless instances[path]
		existed = fs.existsSync(real_path)
		if existed==false and options.create==false
			console.error("Database #{real_path} not exists")
			return null
		instances[path] = 
			sequelize:_.extend(new Sequelize('','','',
				dialect:'sqlite'
				storage:real_path,
				logging:console.log
				#options which are used to define models
				define:{
					underscored:true,#to use _ instead of uppercase letters
					
				}
			),{
				#extend the sync method to keep track of the sync state through the object
				sync:->
					Sequelize::sync.apply(@,Array::slice.call(arguments)).complete =>
						@isSynced = true
			})
			created:!existed
	return instances[path]

exports.createDbFile = (path,cb)->
	real_path = sanitizeDbName(path)
	fs.writeFile real_path,'',cb