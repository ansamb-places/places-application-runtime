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
core = require './core'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
uuid = require 'node-uuid'
argv = require('yargs')
	.default('profile','default')
	.default('profiles_dir','.places')
	.argv

process._argv = argv

###############################
#     Settings management	  #
###############################

places_user_profiles_dir = argv.profiles_dir || ".places"
local_settings_name = "local_settings.json"
env_path = "./settings/env.json"
framework_settings_path = "./settings/framework_settings.json"
root_path = "./"

if typeof argv.root == "undefined"
	root_path = if process.platform=='win32' then process.env.USERPROFILE else process.env.HOME
else
	root_path = argv.root

base_path = path.resolve(root_path,places_user_profiles_dir,argv.profile)

env = require env_path
framework_settings = require framework_settings_path

etc_dir = path.resolve(base_path, "framework", env.etc_dir || "etc")
var_dir = path.resolve(base_path, "framework", env.var_dir || "var")

file_dir = path.resolve var_dir,'files'
places_conf_file_name = env.places_conf_file_name || "places.json"
default_dir = "./defaults"

to_check = [etc_dir,var_dir,file_dir]
for dir in to_check
	# check if folders exists
	unless fs.existsSync dir
		mkdirp.sync(dir,'0755')

places_conf = 
	etc_dir:etc_dir
	var_dir:var_dir
	file_dir:file_dir
	argv:argv

#read local_settings file or use default settings
local_settings = null
places_conf.kernel_conf = framework_settings.kernel_conf
try
	local_settings = require path.join(base_path,local_settings_name)
	places_conf.kernel_conf.port = local_settings.gui_port
	places_conf.http_port = local_settings.http_port
catch e
	places_conf.kernel_conf.port = "1985"
	places_conf.http_port = "8080"


#check and create db paths if required
#db_dir is relative to var dir so we have to build the complete path
db_dir = "db"
places_conf.db_dir = path.join(var_dir,db_dir)
required_db_dirs = ["application","places","core_migration","filesystem"]
for dir in required_db_dirs
	_dir = path.join(places_conf.db_dir,dir)
	unless fs.existsSync _dir
		mkdirp.sync _dir,'0755'
places_conf.application_db_dir = path.join(places_conf.db_dir,required_db_dirs[0])
places_conf.place_db_dir = path.join(places_conf.db_dir,required_db_dirs[1])
places_conf.core_migration_db_dir = path.join(places_conf.db_dir,required_db_dirs[2])
places_conf.filesystem_db_dir = path.join(places_conf.db_dir,required_db_dirs[3])

#database seed configuration
seed_path = path.resolve(default_dir,'database_seed')
places_conf.application_seed_path = path.join(seed_path,'application')


#link connection token
places_conf.kernel_conf.token = local_settings?.gui_auth_token||""

places_conf.kernel_conf.profile = argv.profile || "unknown"
places_conf.kernel_conf.sessid = argv.sessid || null

# Services descriptor path
places_conf.services_descriptor_path = path.join(var_dir,'services')

# extra special config
places_conf.ng_alias = framework_settings?.ng_alias

core.autoload(places_conf)
module.exports = core