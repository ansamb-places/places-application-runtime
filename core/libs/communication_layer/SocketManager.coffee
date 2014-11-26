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
WebSocketClient = require('websocket').client
# BSON = require('bson').native()
# bson = new BSON.BSON([BSON.Code,BSON.Long,BSON.ObjectID,BSON.Binary,BSON.DBRef,BSON.Symbol,BSON.Double,BSON.Timestamp,BSON.MinKey,BSON.MaxKey])
_ = require 'underscore'
_when = require 'when'
uuid = require 'node-uuid'
util = require 'util'
inspect_link = true
{EventEmitter} = require 'events'
try
	linkInspector = require './LinkInspector'
catch e
	console.log "Cannot load link inspector, turn it off"
	inspect_link = false

message_queue = []

auto_reconnect = true
nb_retry = 0
max_retry = 3
retry_delay = 5 #in seconds

class SocketManager extends EventEmitter
	constructor:(@options)->
		@client = new WebSocketClient()
		@socket = null
		@ready = _when.defer()
		@connected = false
		@emit_reply_event = []
	init:->
		return @ready.promise if @connected==true
		nb_retry++ if nb_retry<max_retry
		if not @options or not @options.host or not @options.port or not @options.uri
			@emit "error","missing options"
			return null
		url = "ws://#{@options.host}:#{@options.port}#{@options.uri}"
		token = @options.token
		protocol=null
		@client.removeAllListeners()
		@client.on 'connect',(connection)=>
			console.log "Websocket is now connected"
			@connected = true
			@socket = connection
			@ready.resolve connection
			nb_retry = 0
			@emit 'ready',@client
			@emit 'connected'
			connection.on 'close',=>
				console.log "websocket has been closed"
				@emit 'close'
				@emit 'disconnected'
				@ready = _when.defer()
				@connected = false
				@socket = null
				if auto_reconnect==true
					console.log "trying to reconnect ..."
					@init()
			connection.on 'message',(message)=>
				d = null
				if message.type=='utf8'
					d = message.utf8Data
				else
					return console.error "Received bynary message, unable to decode"
					# d = message.binaryData
				try
					m = JSON.parse(d)
					# m = bson.deserialize(d)
					console.log 'message decoded:',util.inspect(m,{depth:null})
					linkInspector 'in', @options.profile, @options.sessid, m if inspect_link
				catch e
					console.error e
					console.log "websocket:invalid JSON format"
				#check if the message is a reply to a request
				if m.ref_id and @emit_reply_event.indexOf(m.ref_id)!=-1
					@emit_reply_event = _.without @emit_reply_event,m.ref_id
					@emit "_reply:#{m.ref_id}",m
				else
					@emit 'message',m
			@proxyEvent connection,['error']
			#send queued messages if any
			while message_queue.length != 0
				@_send message_queue.shift()
		@client.on 'connectFailed',(error)=>
			console.log "websocket connnect failed:",error
			if auto_reconnect and nb_retry < max_retry
				console.log "try to reconnect in #{retry_delay} s ..."
				setTimeout =>
					@init()
				,retry_delay*1000
			else
				@ready.reject(error)
		console.log "trying to connect to #{url} with token #{token}"
		@client.connect(url,protocol,null,{"X-token":token})
		return @ready.promise
	proxyEvent:(source,events)->
		unless _.isArray events
			events = [events]
		events.forEach (event)=>
			source.on event,=>
				Array::unshift.call(arguments,event) #add event to argument's list
				@emit.apply @,arguments
	runOnReady:(cb)->
		@ready.promise.then cb
	#we assume that the message is a javascript object
	_send:(message)->
		console.log "sending message",util.inspect(message,{depth:null})
		unless message.message_id
			message.message_id = uuid.v4()
		unless @socket?
			console.log "Websocket is not connected!! queued the packet"
			message_queue.push(message)
			return false
		@socket.send JSON.stringify(message)
		# @socket.send bson.serialize(message,true,true)
		#link inspector debugging
		linkInspector 'out', @options.profile, @options.sessid, message if inspect_link
		return true
	req_res_send:(message,options,cb)->
		if _.isUndefined cb
			cb = options
			options = {}
		timedout = false
		timeout_timer = null
		#generate a message id used to match the reply
		message.message_id = uuid.v4() if _.isUndefined(message.message_id)
		if _.isFunction(cb)
			#to know that we are waiting a reply for this message_id
			@emit_reply_event.push message.message_id
			if _.isNumber options.timeout
				timeout_timer = setTimeout ->
					timedout = true
					cb "timeout",null
				,options.timeout
			#suscribe to the reply
			@once "_reply:#{message.message_id}",(reply)->
				if timedout == false
					clearTimeout(timeout_timer) if timeout_timer?
					cb null,reply
		unless @_send(message)
			console.error "Trying to send a message but kernel is not connected"
	close:->
		@client.close()

exports = module.exports = SocketManager
