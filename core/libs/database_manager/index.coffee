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
fs = require process.cwd()+'/lib/safeFs'
_ = require 'underscore'
path = require 'path'
_when = require 'when'
async = require 'async'
nodefn = require 'when/node/function'
Sequelize = require 'sequelize'
dbHelper = require './dbHelper'
#WARNING this require can change if Sequelize's module structure change
DataTypes = require 'sequelize/lib/data-types'
MigrationManager = require path.join(process.cwd(),'lib','MigrationManager')

storage_cache = {}
high_cache = {}
model_dir = 'models'
storage_dir = 'storage'
db_ext = 'sqlite'
defaut_name = "db.#{db_ext}"
application_db_name = "application.#{db_ext}"
filesystem_db_name = "filesystem.#{db_ext}"
core_migration_db_name = "migration.#{db_ext}"

###
			private functions
###

#this function create a proxy to prefix all model's name with a string
#the function return the created model and the real name defined by the user as the model name
createSequelizeProxy = (prefix_name,sequelize_instance)->
	#the first parameter of the function is the modelName that we want to override
	return ->
		args = Array::slice.call(arguments)
		original_name = args[0]
		args[0] = if prefix_name==null then original_name else "#{prefix_name}_#{original_name}"
		return {
			realName:original_name,
			model:sequelize_instance.define.apply sequelize_instance,args
		}

#defined models can expose a function 'associate' which is called with all models to define relations
createAssociations = (model,models)->
	if model.options.hasOwnProperty 'associate'
		model.options.associate.call(model,models)

enhanceModel = (sequelize_instance,model,models)->
	createAssociations(model,models)
	if model.options.hasOwnProperty '_placesHelpers'
		model.__places__ = {}
		_.each model.options._placesHelpers,(method,name)->
			models_objects = _.extend {
				self:model
			},models
			context = 
				sequelize:sequelize_instance
				Sequelize:Sequelize
				models:models_objects
			model.__places__[name] = method.bind(context)

normalizeDbName = (name)->
	return name.replace(/\s/g,"_")


module.exports = (options,imports,register)->
	core_models_path = 
		options.core_models_path || path.join(process.cwd(),'core','models')
	core_migration_database_storage_path = options.core_migration_database_storage_path
	core_migration_models_path = path.join(core_models_path,options.core_migration_models_dir)
	place_database_storage_path = 
		options.place_database_storage_path || path.join(process.cwd(),'databases','places','storage')
	place_models_path = path.join(core_models_path,options.place_models_dir)
	application_database_storage_path = 
		options.application_database_storage_path || path.join(process.cwd(),'databases','application','storage')
	application_models_path = path.join(core_models_path,options.application_models_dir)
	application_database_seed_path = 
		options.application_database_seed_path || path.join(process.cwd(),'databases','application','seed')
	migration_path = options.migration_path
	application_registery = imports["application.registery"]
	filesystem_models_path = path.join(core_models_path,options.filesystem_models_dir)
	filesystem_database_storage_path =
		options.filesystem_database_path || path.join(process.cwd(), 'databases','filesystem')
	server = imports["server"]
	express_app = server.app
	
	#retrieve migration version to check further if the database have to be migrated to another version 
	try
		migration_version = require(path.join(core_models_path,'migration.json'))
	catch e
		console.error("No migration file found to operate migrations")
		migration_version = null

	expose = {}

	getMigrationDatabase = (cb)->
		return cb(null,high_cache["migration"]) if high_cache.hasOwnProperty "migration"
		db_path = path.join(core_migration_database_storage_path,core_migration_db_name)
		sequelize = dbHelper.getSqliteInstance(db_path,{create:true}).sequelize
		fs.readdir core_migration_models_path,(err,files)->
			return cb(err,null) if err?
			models = {}
			files.forEach (file)->
				model_module = require path.join(core_migration_models_path,file)
				m = model_module(createSequelizeProxy(null,sequelize),DataTypes)
				models[m.realName] = m.model
			_.each models,(model)->
				createAssociations model,models
			sequelize.sync().complete (err)->
				return cb(err,null) if err?
				high_cache["migration"] = {models:models,sequelize:sequelize}
				cb(null,high_cache["migration"])

	_getDatabase = (models_path,storage_path,name,options,cb)->
		if _.isUndefined(cb)
			cb = options
			options = {}
		db_path = path.join(storage_path,name)
		db = {global:{},prefixed:{}}
		instance = dbHelper.getSqliteInstance db_path,options
		if instance==null
			return cb(new Error("Unable to get Database #{name}"))
		sequelize = instance.sequelize
		created = instance.created
		#load models
		models_path.forEach (p)->
			if _.isString(p)
				mp = p
				prefix = null
			else
				mp = p.path
				prefix = p.prefix
			fs.readdirSync(mp).forEach (file)->
				model_path = path.join(mp,file)
				model_def = require model_path
				proxy_model = model_def createSequelizeProxy(prefix,sequelize),DataTypes
				#realName define by the user is accessible through proxy_model.realName
				model = proxy_model.model
				if prefix==null
					db.global[proxy_model.realName] = model
				else
					db.prefixed[prefix] = {} if _.isUndefined(db.prefixed[prefix])
					db.prefixed[prefix][proxy_model.realName] = model

		#check if associations are defined
		_.each db.global,(model)->  #for global models
			enhanceModel sequelize,model,db.global
		_.each db.prefixed,(app_models)-> #for prefixed models
			_.each app_models,(model)->
				enhanceModel sequelize,model,{global:db.global,myModels:app_models}

		#sync database (create tables if not exists)
		sequelize.sync().complete (err)->
			return cb(err,null) if err?
			cb null,{models:db,sequelize:sequelize},created

	db_promise = null #to create a singleton pattern
	expose.getApplicationDatabase = (cb)->
		if db_promise==null
			db_promise = _when.promise (final_resolve,final_reject)->
				models_path = [application_models_path]
				_getDatabase(
					models_path,
					application_database_storage_path,
					application_db_name,
					{create:true}
				,(err,object,created)->
					args = Array::slice.call(arguments)
					if err==null
						#seed the database and create migration information if required
						if created
							migration_init_done = _when.promise (resolve,reject)->
								if migration_version==null #no version defined
									return resolve("No migration version defined for core models")
								getMigrationDatabase (err,db)->
									return reject(err) if err?
									row = 
										type:'application'
										name:application_db_name
										last_version:""
										current_version:migration_version.application
									db.models.database.create(row,{raw:true}).done (err,r)->
										if err?
											reject(err)
										else
											resolve()
							migration_init_done.then ->
								seed = require(application_database_seed_path)
								seed object,(err)->
									return final_reject(err) if err?
									new_args = args.slice(1)
									final_resolve.apply(null,args.slice(1))
							,(error)->
								final_reject error
							.catch (error)->
								console.log error.stack
								final_reject error
						else
							final_resolve.apply(null,args.slice(1))
					else
						final_reject err
				)
		db_promise.then ->
			args = Array::slice.call(arguments)
			args.unshift(null)
			cb.apply null,args
		,(error)->
			console.log error.stack
			cb.call null,error
		.catch (error)->
			console.log error.stack
			cb error.message

	expose.getFilesystemDatabase = (cb)->
		models_path = []
		models_path.push filesystem_models_path
		#cache management
		cache_key = "filesystem"
		return cb(null,high_cache[cache_key]) if high_cache.hasOwnProperty(cache_key)

		_getDatabase models_path,filesystem_database_storage_path,filesystem_db_name,{create:true},(err,database,created)->
			#we don't propagate the last parameter otherwise async lib create an array with it
			high_cache[cache_key] = database if err==null
			cb err,database

	#this function return a raw sequelize instance without loading all database models
	expose.getRawDatabaseForPlace = (db_name,options)->
		dbHelper.getSqliteInstance path.join(place_database_storage_path,db_name),options

	expose.getRawDatabaseForApplication = (options)->
		dbHelper.getSqliteInstance path.join(application_database_storage_path,application_db_name),options

	###
	All models will be loaded according to a defined scheme
	models_path can be an array or a simple path. Also it can be a string or an object like below:
	{
		path:string
		prefix:string
	} 
	the prefix allow to add a prefix before the table name to avoid models collisions

	the module return an object defined as below:
	{
		sequelize:object (the Sequelize instance bind to the database)
		models:{
			global:Object (associative array with keys corresponding to models defined without prefix)
			'prefix_name':Object (associative array with keys corresponding to models defined whitin this prefix)
		}
	}
	to gain access to model 'Model' within the prefix 'Application1' : object.models.prefixed.Application1.Model
	to gain access to model 'Content' defined without prefix: object.models.global.Content
	###
	expose.getDatabaseForPlace = (place_name,options,cb)->
		if _.isUndefined options
			cb = models_path
			models_path = []
			options = {}
		else if _.isUndefined cb
			cb = options
			options = {}
		cb(new Error("missing parameters"),null) if arguments.length<2

		#cache management
		cache_key = "place:#{place_name}"
		return cb(null,high_cache[cache_key]) if high_cache.hasOwnProperty(cache_key)

		db_name = "#{normalizeDbName(place_name)}.#{db_ext}"
		models_path = []
		#regular place models
		models_path.push place_models_path
		#application specific models
		app_models = application_registery.getAllDbModelsPath()
		_.each app_models,(path,app_name)->
			models_path.push {path:path,prefix:app_name}
		_getDatabase models_path,place_database_storage_path,db_name,(err,database,created)->
			#we don't propagate the last parameter otherwise async lib create an array with it
			high_cache[cache_key] = database if err==null
			cb err,database

	#this function will create the database on the file system
	#WARNING it will override existing database
	expose.createDatabaseForPlace = (place_name,cb)->
		db_name = "#{normalizeDbName(place_name)}.#{db_ext}"
		p = path.join place_database_storage_path,db_name
		#create an empty file
		dbHelper.createDbFile p,(err)->
			return cb(err) if err?
			#create migration datas
			migration_init_done = _when.promise (resolve,reject)->
				if migration_version==null #no version defined
					return resolve("No migration version defined for core models")
				getMigrationDatabase (err,db)->
					return reject(err) if err?
					row = 
						type:'place'
						name:db_name
						last_version:""
						current_version:migration_version.place
					db.models.database.create(row).done (err,r)->
						if err?
							reject(err)
						else
							resolve()
			migration_init_done.then ->
				cb null
			,(error)->
				cb error

	expose.deleteDatabaseForPlace = (place_name,callback)->
		db_name = "#{normalizeDbName(place_name)}.#{db_ext}"
		async.waterfall [
			(cb)->
				dbHelper.deleteSqliteInstance path.join(place_database_storage_path,db_name),cb
			(cb)->
				#delete cached object
				delete high_cache["place:#{place_name}"]
				#delete migration data
				if migration_version==null #no version defined
					console.log("No migration version defined for core models")
					return cb null
				getMigrationDatabase (err,db)->
					return cb(err) if err?
					row = 
						type:"place"
						name:"#{normalizeDbName(place_name)}.#{db_ext}"
					console.log "delete migration data:",row
					db.models.database.destroy(row).done (err)->cb(err)
		],(err)->
			callback(err,err==null)

	#migrate databases if required before registering the plugin
	migration_done = _when.defer()
	getMigrationDatabase (err,db)->
		if err?
			return migration_done.reject(err)
		db.models.database.findAll().done (err,databases)->
			return migration_done.reject(err) if err?
			async.each databases,(db_to_migrate,final_callback)->
				console.log "[MIGRATION] check migration for #{db_to_migrate.name}"
				instance = null
				type = db_to_migrate.type
				if type=="application"
					instance = expose.getRawDatabaseForApplication()
				else
					instance = expose.getRawDatabaseForPlace(db_to_migrate.name)
				return final_callback(new Error("Database file not found")) if instance==null
				current_version = db_to_migrate.current_version
				if current_version==""
					console.error("No current version defined for migrating #{db_to_migrate.name}")
					return final_callback(null)
				migration = new MigrationManager(
					instance.sequelize,
					current_version,
					migration_version[type],
					path.join(migration_path,type)
				)
				migration.on 'end',(error,final_version,migrated)->
					console.error(error) if error?
					if migrated==true
						db_to_migrate.last_version = current_version
						db_to_migrate.current_version = final_version
						db_to_migrate.save().done (err)->
							console.error(err) if err?
							final_callback(err)
					else
						final_callback(null)
				migration.run()
			,(err)->
				console.error err if err?
				migration_done.resolve()


	######## HTTP API ############
	prefix = server.url_prefix.core_api+'/database'
	express_app.get "#{prefix}/",(req,res)->
		async.waterfall [
			(callback)->
				getMigrationDatabase callback
			(migration_db,callback)->
				migration_db.models.database.findAll({},{raw:true}).done callback
		],(err,result)->
			res.send {err:err,data:result}


	migration_done.promise.then ->
		register null,
			database_manager:expose
	,(err)->
		console.error err
