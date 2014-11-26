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
EventEmitter = require('eventemitter2').EventEmitter2

module.exports = (options,imports,register)->
	server = imports["server"]
	express = server.app
	protocol_builder = imports["protocol.builder"]
	com_layer = imports.communication_layer
	events = imports.events.namespaced("server_link")
	link_builder = protocol_builder.link_mgmt
	api = new EventEmitter
	link_status = null
	_.extend api,
		status:
			connected:"connected"
			disconnected:"disconnected"
		#if a callback is defined, getStatus will fetch the status from the kernel
		#otherwise it will return the last known status
		getStatus:(cb)->
			if _.isFunction(cb)
				link_builder.getStatus().send {timeout:2000},(err,reply)->
					_err = err
					if err == null
						if reply.code == 200
							api.setStatus reply.data.status if reply?.data?.status
						else
							_err = "Network error"
					cb _err,reply?.data?.status
			else
				return link_status
		setStatus:(new_status,options)->
			options ?= {}
			if _.values(api.status).indexOf(new_status) != -1 and new_status != link_status
				link_status = new_status
				com_layer.setConditionStatus "server_link:connected",link_status==api.status.connected
				api.emit "status:change",new_status
				if options.notify_ui == true
					events.emit "status:change",new_status
				return true
			else
				return false
		isLinkConnected:(cb)->
			if _.isFunction(cb)
				@getStatus (err,status)->
					cb err,status==api.status.connected
			else
				@getStatus()==api.status.connected
		connect:(cb)->
			timeout = 10000
			link_builder.connect({timeout:timeout}).send {timeout:timeout},(err,reply)->
				isSuccess = reply?.code==200
				api.setStatus api.status.connected if isSuccess
				cb err,isSuccess

	###############################################
	########			HTTP API 			#######
	###############################################

	prefix = server.url_prefix.core_api+'/server_link'
	express.get "#{prefix}/status/",(req,res)->
		api.isLinkConnected (err,connected)->
			res.send {err:err,connected:connected}
	express.get "#{prefix}/connect/",(req,res)->
		if not api.isLinkConnected()
			api.connect (err,connected)->
				res.send {err:err,connected:connected}
		else
			res.send {err:null,connected:true}


	# check initial status before register the component
	api.isLinkConnected (err,connected)->
		register null,{server_link_management:api}