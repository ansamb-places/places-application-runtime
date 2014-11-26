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
ApplicationManager = require './ApplicationManager'
_ = require 'underscore'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'

module.exports = (options,imports,register)->
	server = imports.server
	express_app = server.app
	apps_dir = options.apps_dir||process.cwd()+"/applications"
	file_dir = options.file_dir

	applicationManager = new ApplicationManager(apps_dir)
	report = applicationManager.autoload()

	#create file directories for apps who need it
	_.each applicationManager.getApplications(),(app)->
		return if app?.file_storage != true
		app_file_dir = path.join file_dir,app.name
		unless fs.existsSync app_file_dir
			mkdirp.sync app_file_dir,'0755'
		app.file_dir_path = app_file_dir

	#HTTP API
	prefix = server.url_prefix.core_api+'/application'
	express_app.get "#{prefix}/",(req,res)->
		res.send applicationManager.getSanitizedApplications()

	register null,
		"application.registery":applicationManager