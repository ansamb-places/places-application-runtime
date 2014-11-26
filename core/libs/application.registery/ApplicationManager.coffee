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
utils = require process.cwd()+'/lib/utils/utils'
fs = require process.cwd()+'/lib/safeFs'
path = require 'path'
MigrationManager = require process.cwd()+'/lib/MigrationManager'
ApplicationValidator = require './ApplicationValidator'
async = require 'async'
_when = require 'when'
{EventEmitter}   = require('events')
_ = require 'underscore'

class ApplicationManager extends EventEmitter
	constructor:(@base_path)->
		@app_require_script = "index"
		@applications = {}
		@defer = null
		@loadReport = null
	registerApplication:(app_path)->
		done = (err,loaded)->
			return {err:err,loaded:loaded}
		json = utils.loadJSONfile(path.join(app_path,'application.json'))
		return done "Invalid application descriptor",false if json==null or _.isUndefined(json)
		#load module
		try
			if json.js == true
				module = require path.join(app_path,@app_require_script+".js")
			else
				module = require path.join(app_path,@app_require_script)
			valid = ApplicationValidator(module)
			if valid==false
				console.error("Application #{json.name} is not valid!!")
				# @emit 'error',"Unable to load #{json.name}"
				return done "Application #{json.name} is not valid!!",false
			@applications[json.name] = json
			_.extend @applications[json.name],
				module : module
				path : app_path
				initialized:false
			@emit 'loading_app:done',json.name
			return done null,true
		catch e
			console.error("Unable to load #{json.name}:",e)
			# @emit 'error',"Unable to load #{json.name}",e
			return done "Unable to load #{json.name}:",false
	initApplication:(app_name,router,db_manager,list_place,cb)->
		console.log "init application #{app_name}"
		app = @getAppByName app_name
		return cb("Application not found",false) if _.isUndefined(app)
		app.module.init(router)
		@checkMigrationForPlaceApp app_name,db_manager,list_place,(err,migrated)->
			if err==null and migrated==true
				app.initialized = true
			cb err,migrated
	getApplications:->
		@applications
	getApplicationsWithStorage:->
		_.chain(@applications).filter (app)->
			app?.file_storage==true
		.map (app)->
			app.name
		.value()
	forEach:(callback)->
		_.each @applications,callback
	getSanitizedApplications:->
		_apps = {}
		_.each @applications,(app,key)->
			_apps[key] = _.omit app,'module'
		return _apps
	getApplicationForContentType:(content_type)->
		_.find @applications,(app)=>app.contentType==@getPrimaryContentType(content_type)
	isContentTypeManaged:(content_type)->
		@getAllContentTypes().indexOf(@getPrimaryContentType(content_type))!=-1
	getPrimaryContentType:(content_type)->
		regexp= /^(.*):/
		result= regexp.exec(content_type)
		return if result then result[1] else content_type
	getPathForContentType:(content_type)->
		app = @getApplicationForContentType content_type
		if app?
			return app.file_dir_path
		else return null
	getAllContentTypes:->
		return _.map @applications,(app)->app.contentType
	getAppByName:(name)->
		if @applications.hasOwnProperty(name)
			return @applications[name]
		else return null
	getAllDbModelsPath:->
		models = {}
		_.each @applications,(app)=>
			models[app.name] = path.join(app.path,app.models_dir)
		return models
	checkMigrationForPlaceApp:(app_name,db_manager,list_place,cb)->
		#TODO check migrations
		app_descriptor = @applications[app_name]
		return cb("Application not found",false) if _.isUndefined(app_descriptor)
		unless app_descriptor.hasOwnProperty('models_version')
			console.log "application have no version defined"
			return cb(null,true) 
		async.waterfall [
			(callback)=>
				db_manager.getApplicationDatabase callback
			(db,callback)=>
				db.models.global.application.findOrCreate(
					{name:app_descriptor.name},
					{
						models_version:app_descriptor.models_version
						author:app_descriptor.author
					}
				).done (err,application,created)->
					callback err,db,application,created
			(db,application,created,callback)->
				if created #no migration required
					console.log "no migration required"
					return callback(null,true,app_descriptor.models_version)

				#check if migration is required
				a = utils.versionToNumber(application.models_version,2)
				b = utils.versionToNumber(app_descriptor.models_version,2)
				if a>=b
					console.log "no migration required"
					return callback(null,true,app_descriptor.models_version)

				if list_place.length==0
					#no migration required as we don't have any place's databases
					application.models_version = app_descriptor.models_version
					return application.save().done (err)->
						callback(err,true,app_descriptor.models_version)
				#we have to apply the migration process for each place
				list_place.forEach (place)=>
					sequelize = db_manager.getRawDatabaseForPlace place
					console.log "checking migration from #{application.models_version} to #{app_descriptor.models_version}"
					m = new MigrationManager(
						sequelize,
						application.models_version,
						app_descriptor.models_version,
						path.join(app_descriptor.path,app_descriptor.migration_dir)
					)
					unless m.isMigrationRequired()
						#migration not required
						return callback(null,true,app_descriptor.models_version)
					m.on 'end',(error,version)->
						application.models_version = version
						application.save().done (err)->
							callback(error,true,version)
					m.run()
						#TODO create a promise resolved when all migrations have been done!!!
		],cb
	autoload:->
		if @loadReport==null
			apps = fs.readdirSync(@base_path)
			@loadReport = {}
			_.each apps,(item)=>
				p = path.join(@base_path,item)
				@loadReport[p] = @registerApplication(p)
		return @loadReport

module.exports = ApplicationManager