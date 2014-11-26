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
_ = require 'underscore'
ZSchema = require 'z-schema'
validator = new ZSchema sync:true
#encapsulate the message to provide a network object
uuid = require 'node-uuid'
class NetworkDecorator
	constructor:(@communication_layer,@builder,@name,@message,@_conditions)->
		@message.message_id = uuid.v4()
	send:(options,cb)->
		if _.isUndefined cb
			cb = options
			options = {}
		options = _.extend options,{_conditions:@_conditions ? null}
		if @builder?.schema? and @builder.schema[@name] and not validator.validate @message,@builder.schema[@name]
				return cb "Invalid JSON schema",null
		@communication_layer.send @message,options,cb
	getMessageId:->
		return @message.message_id
#this function will encapsulate all methods of the given object
#and call the NetworkDecorator
module.exports = (communication_layer,builder)->
	new_object = {}
	for name,f of builder.api
		((name,f)->
			new_object[name] = ->
				obj = f.apply(null,arguments)
				if obj.message and obj._conditions
					message = obj.message
					_conditions = obj._conditions
				else
					message = obj
					_conditions = null
				new NetworkDecorator(
					communication_layer,
					builder,
					name,
					message,
					_conditions
				)
		)(name,f)
	return new_object