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
async = require 'async'
_ = require 'underscore'
require_place_name = require("../../common_lib/express_middlewares").require_place_name

###
	when the place has no owner, the owner is the current user
###
module.exports = (options,imports,register)->
	server = imports.server
	express = server.app
	place_lib = imports["api.place"]
	content_lib = imports["api.place.content"]
	api =
		getAllPlaceWithLastContent:(filter,options,cb)->
			if _.isUndefined cb
				cb = options
				options = {raw:true}
			filter = filter||{}
			#filter.status = place_lib.status.validated
			place_lib.getAllPlace filter,options,(err,places)->
				return cb err,null if err?
				map_func = (item,callback)->
					content_lib.getLastContentFromOtherForPlace item.id,(err,content)->
						callback err,_.extend(item,{last_content:content})
				async.map places,map_func,cb

	###
	%%%%%%%%%%%%%%%%%% http api definition %%%%%%%%%%%%%%%%%%%%%%%%
	###

	prefix = server.url_prefix.core_api+'/places/helper'
	express.get "#{prefix}/place_with_last_content/",(req,res)->
		filter = {}
		filter.type = req.query.type if req.query.type
		options = {raw:true}
		api.getAllPlaceWithLastContent filter,options,(err,places)->
			res.send {err:err,data:places}

	express.get "#{prefix}/content_without_collection/",require_place_name,(req,res)->
		place_id = req.query.place_name
		content_lib._getContentsWithFilter req.query.place_name,null,1,(err,contents)->
			err = err.toString() if err instanceof Error
			res.send {err:err,data:contents}

	register null,{"api.place.helper":api}