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
_when = require 'when'
path = require 'path'
fs = require 'fs'
ServiceRequester = require './ServiceRequester'

#just to simplify things for API users
services_aliases =
	"alias_search":"alias_search"
	"resend_code":"resend_code"

module.exports = (options,imports,register)->
	server = imports["server"]
	express = server.app
	p = options.service_path
	descriptor_path = path.join(p,'descriptor.json')
	descriptor = null
	try
		descriptor = require descriptor_path
	catch e
		console.log "No valid service descriptor found"

	credentials = null

	api =
		setAuthCredentials:(login,password)->
			credentials =
				login:login
				password:password
		getAuthCredentials:->
			return credentials
		getServiceList:->
			if descriptor?
				return _.keys descriptor
			else
				return null
		getServices:->
			return descriptor
		# descriptor could be an object or a string
		setDescriptor:(_descriptor)->
			file_data = ""
			if _.isObject _descriptor
				descriptor = _descriptor
				file_data = JSON.stringify(_descriptor,null,'\t')
			else
				try
					descriptor = JSON.parse(_descriptor)
					file_data = _descriptor
				catch e
					error = "Descriptor is not a valid JSON object"
					console.log error
					return error
			fs.writeFileSync descriptor_path,file_data
		requestService:(name,args,options,cb)->
			if _.isUndefined(cb)
				cb = options
				options = {}
			if services_aliases.hasOwnProperty(name)
				name = services_aliases[name]
			return cb "Service not found" if descriptor == null or not descriptor[name]
			auth = options.auth || credentials || null
			if auth == null
				return cb "No auth credentials"
			ServiceRequester descriptor[name],auth,args,cb

	### %%%%%%%% HTTP API %%%%%%%%%%%%% ###

	prefix = server.url_prefix.core_api+'/services'
	express.get "#{prefix}/",(req,res)->
		return res.send descriptor
	express.get "#{prefix}/:name",(req,res)->
		api.requestService req.param("name"),req.query,(err,reply)->
			res.send {err:err,reply:reply}

	fs.exists p,(exists)->
		if exists == false
			fs.mkdirSync p
		register null,{'external_service_manager':api}
