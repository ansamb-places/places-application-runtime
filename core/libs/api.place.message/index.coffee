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
_when = require 'when'
_ = require 'underscore'
async = require 'async'
require_place_name = require("../../common_lib/express_middlewares").require_place_name
module.exports = (options,imports,register)->
	place_lib = imports["api.place"]
	protocol_builder = imports["protocol.builder"]
	server = imports["server"]
	express_app = server.app

	api =
		sendMessage:(place_id,dst,content_type,payload,cb)->
			async.waterfall [
				(callback)->
					place_lib.checkPlace place_id,callback
				(place_exists,callback)->
					if place_exists
						protocol_builder.message.buildMessage
							place:place_id
							dst:dst
							content_type:content_type
							payload:payload
						.send callback
					else
						callback "Place not found"
			],(err,reply)->
				console.log err if err?
				return cb err,false if err?
				if reply.code!=202
					cb "Receive a non-202 reply code (#{reply.code})",false
				else
					cb null,true

	########################### HTTP API ##################################
	prefix = "#{server.url_prefix.core_api}/message"
	express_app.post "#{prefix}/:content_type",require_place_name,(req,res)->
		place_id = req.query.place_name
		dst = req.query.dst
		content_type = req.param 'content_type'
		_when.promise (resolve,reject)->
			if dst?
				api.sendMessage place_id,dst,content_type,req.sanitize(req.body),(err,ok)->
					if err?
						reject err
					else
						resolve ok
			else
				reject("Invalid destination")
		.done (ok)->
				res.send {err:null,ok:ok}
		,(error)->
			console.log err if err?
			error = error.message if _.isObject(error)
			res.send {err:error,ok:false}

	register null,{"api.place.message":api}