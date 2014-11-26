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
fs = require 'fs'
path = require 'path'
_when = require 'when'
_ = require 'underscore'
architect = require 'architect'
utils = require '../lib/utils/utils'
{EventEmitter}   = require('events')

class coreLoader extends EventEmitter
	constructor:->
		@defer = _when.defer()
		@libs = {}
	autoload:(config)->
		first_load = false
		base_path = path.join(process.cwd(),'core','libs')
		#create core config object
		core_config = [
			{
				packagePath:path.join(base_path,"communication_layer"),
				config:config.kernel_conf
			},
			{
				packagePath:path.join(base_path,"server"),
				port:config.http_port||8080
			},
			{
				packagePath:path.join(base_path,"external_service_manager"),
				service_path:config.services_descriptor_path
			},
			{
				packagePath:path.join(base_path,"database_manager"),
				core_models_path:path.join(process.cwd(),'core','models'),
				core_migration_database_storage_path:config.core_migration_db_dir,
				core_migration_models_dir:'core_migration',
				application_models_dir:'application',
				application_database_storage_path:config.application_db_dir,
				application_database_seed_path:config.application_seed_path,
				place_models_dir:'place',
				place_database_storage_path:config.place_db_dir
				migration_path:path.join(process.cwd(),'core','migrations'),
				filesystem_database_path:config.filesystem_db_dir
				filesystem_models_dir:'filesystem'
			},
			{
				packagePath:path.join(base_path,"application.registery"),
				apps_dir:path.join(process.cwd(),"applications"),
				file_dir:config.file_dir
			},
			path.join(base_path,"server_link_management"),
			path.join(base_path,"application.broker"),
			path.join(base_path,"framework.router"),
			path.join(base_path,"client.websocket"),
			path.join(base_path,"content_manager"),
			{ packagePath: path.join(base_path,"api.place"), file_dir: config.file_dir },
			path.join(base_path,"api.place.helper"),
			path.join(base_path,"api.place.content"),
			path.join(base_path,"api.place.ansamber"),
			path.join(base_path,"api.place.sync"),
			path.join(base_path,"api.place.message"),
			{
				packagePath:path.join(base_path,"api.contact"),
				ng_alias:config.ng_alias
			}
			path.join(base_path,"api.account"),
			path.join(base_path,"api.credential"),
			path.join(base_path,"protocol.handler"),
			path.join(base_path,"protocol.handler.sync"),
			path.join(base_path,"protocol.handler.content"),
			path.join(base_path,"protocol.handler.contact"),
			path.join(base_path,"protocol.handler.account"),
			path.join(base_path,"protocol.handler.place"),
			path.join(base_path,"protocol.handler.message"),
			path.join(base_path,"protocol.handler.fs"),
			path.join(base_path,"protocol.handler.server_link_mgmt"),
			path.join(base_path,"protocol.builder"),
			path.join(base_path,"document.network.broker"),
			path.join(base_path,"events"),
			path.join(base_path,"events.socketio"),
			{ packagePath: path.join(base_path,"file.watcher"), file_dir: config.file_dir },
			path.join(base_path,"notification_manager"),
			{ packagePath:path.join(base_path,"avatar_manager"), var_dir: config.var_dir },
			path.join(base_path,"update_manager"),
			path.join(base_path,"api.rss")
		]
		start_time = new Date
		a = architect.createApp architect.resolveConfig(core_config,base_path),(err,app)=>
			if err
				@defer.reject(new Error("Core load failed"))
				return console.log "Core load failed"
			time = new Date - start_time
			console.log "It takes #{time/1000} s to initialize core libs"
			app.getService("server").set_is_ready(true)
			@defer.resolve(app)
			console.log "App ready"
			#validate the step "core_init"
			app.getService("server").stepManager.goToStep("account_check",{validate_current:true})
		a.on 'error',(error)->
			console.log error.stack
		return @defer.promise
	onCoreReady:(cb)->
		@defer.promise.then ->
			cb module.exports

coreLoader = new coreLoader
#autoload all core libs when this module is first required
# coreLoader.autoload()

module.exports = coreLoader
