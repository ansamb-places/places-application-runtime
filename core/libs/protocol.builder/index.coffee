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
path = require 'path'
NetworkDecorator = require './NetworkDecorator'

module.exports = (options,imports,register)->	
	communication_layer = imports["communication_layer"]
	concrete_builders_dir = path.join(__dirname,"concrete_builders")
	builders = {}
	#load all builders
	fs.readdir concrete_builders_dir,(err,files)->
		for file in files
			try
				builder = require path.join(concrete_builders_dir,file)
				builders[builder.name] = NetworkDecorator(communication_layer,builder)
			catch e
				console.log "Unable to load one protocol builder"
		register null,{
			"protocol.builder":builders
		}