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
SocketManager = require './SocketManager'
_ = require 'underscore'
_when = require 'when'


# readyToReceive lock
# while this var is not set to true, all incoming message will be queued
readyToReceive = false
incoming_queue = []
handleIncomingQueue = ->
	_.each incoming_queue,(message)->
		onMessage message
	incoming_queue = []

### Private helpers ###
validateMessage = (message)->
	return _.isObject(message)
	#TODO implement message validation
	#return message.dpl and message.spl

messageHandler = null
onMessage = (message)->
	#TODO implement message validation
	unless validateMessage(message)
		return console.log "websocket:received an invalid message"
	
	if readyToReceive == false
		console.log "[INFO] Queue incoming message"
		return incoming_queue.push(message)

	throw new Error("No message handler defined") if messageHandler==null
	messageHandler(message)

### 
 conditions definition.
 -------------------------------------------------------------------------
 A requirement is a special condition which can be satisfied or not.
 A packet being sent can ask for a requirement to be satisfied otherwise
 the packet is queued and not sent until the requirement become satisfied
###
conditions = ['server_link:connected']
conditions_status = {}
conditions_queue = []
_.each conditions,(requirement)->
	conditions_status[requirement] = false


module.exports = (options,imports,register)->
	socketManager = new SocketManager(options.config)
	#listen to events
	socketManager.on 'message',onMessage
	socketManager.on 'error',(error)->
		console.log "Websocket error:",error

	# conditions management helpers
	condition_check = (conditions)->
		return _.every(conditions,(cond)->conditions_status[cond])
	conditions_change = ->
		to_remove = []
		_.each conditions_queue,(item,index)->
			conds = item.options._conditions
			if condition_check(conds) == true
				api.send item.message,item.options,item.cb
				to_remove.push index
		for index in to_remove
			conditions_queue.splice(index,1)

	api =
		connect:->
			return socketManager.init()
		setMessageHandler:(handler)->
			messageHandler = handler
		getStatus:->
			return if socketManager.connected then "connected" else "disconnected"
		disconnect:->
			socketManager.close()
		send:(message,options,cb)->
			if _.isUndefined(cb) and _.isFunction(options)
				cb = options
				options = {}
			# check if conditions are met before sending packet to socket_manager
			if options._conditions == null or condition_check(options._conditions)
				socketManager.req_res_send message,options,cb
			else
				console.log "[INFO] conditions to send packet are not met, queue the packet"
				conditions_queue.push({message:message,options:options,cb:cb})
		inject:(message)->
			onMessage(message)
		setConditionStatus:(name,status)->
			if conditions.indexOf(name) != -1
				unless _.isBoolean(status)
					return false
				if conditions_status[name] != status
					conditions_status[name] = status
					console.log "[INFO] Condition #{name} is now set to #{status}"
					conditions_change()
				return true
			else
				console.log "[INFO] Condition #{name} not found for com_layer"
				return false
		readyToReceive:->
			readyToReceive = true
			handleIncomingQueue()
	#this api will be exposed to applications
	app_api = 
		send:api.send
		getStatus:api.getStatus

	api.connect().done ->
		register null,{
			communication_layer:api
			application_communication_api:app_api
		}
	,(error)->
		register error,null
