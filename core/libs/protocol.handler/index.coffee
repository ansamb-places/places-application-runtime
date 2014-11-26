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
HandlerManager = require '../../common_lib/HandlerManager'
module.exports = (options,imports,register)->
	com_layer = imports["communication_layer"]
	handlerManager = new HandlerManager()

	normalizeMessage = (message)->
		if message.hasOwnProperty('date') and typeof message.date == "string"
			_date = +(message.date)
			message.date = _date unless isNaN(_date)
		return message
	messageHandler = (message)->
		message = normalizeMessage message
		name = message.protocol
		handler = handlerManager.getHandler(name)
		if typeof handler=="undefined"
			# throw new Error("No protocol handler for protocol #{name}")
			return console.error("No protocol handler for protocol #{name}")
		handler(message)
	com_layer.setMessageHandler messageHandler
	expose = 
		registerProtocolHandler:handlerManager.registerHandler
		handleMessage:messageHandler

	register null,{"protocol.handler":expose}