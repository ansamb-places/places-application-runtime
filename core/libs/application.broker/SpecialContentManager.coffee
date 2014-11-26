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
_ = require 'underscore'
interface_dir = path.join __dirname,'specialContentInterfaces'

class SpecialContentManager
	constructor:(@db_manager)->
		#load special types and corresponding interfaces
		@interfaces = {}
		modules = fs.readdirSync interface_dir
		_.each modules,(module)=>
			m = null
			try
				m = require path.join(interface_dir,module)
			catch e
				return console.log "Error while loading #{module} interface"
			@interfaces[m.name] = m.crud
	containContentType:(content_type)->
		return (_.keys(@interfaces)).indexOf(content_type)!=-1
	addBehaviourToCrud:(original_crud)->
		_.each original_crud,(fun,name)=>
			#original prototype is always beginning with place_id,content
			original_crud[name] = =>
				args = Array::slice.call(arguments)
				place_id = args[0]
				content = args[1]
				cb = _.last args
				return cb("Content is null",null) if content==null
				content_type = content.content_type
				if @containContentType(content_type)
					args = args.slice(1)
					@db_manager.getDatabaseForPlace place_id,(err,db)=>
						return cb(err,null) if err?
						args.unshift(db)
						@interfaces[content_type][name].apply null,args
				else
					#call the original function
					fun.apply null,args

module.exports = SpecialContentManager