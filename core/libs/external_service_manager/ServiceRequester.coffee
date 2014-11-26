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
request = require 'request'
path = require 'path'
fs = require path.join(process.cwd(),'lib','safeFs')
alias =
	"method":"method"
	"params":"params"
	"uri":"uri"
	"return":"return"
	"auth":"auth"


# load all protocol requester
requesters = {}
requesters_path = path.join(__dirname,'requesters')
files = fs.readdirSync requesters_path
_.each files,(file)->
	try
		m = require path.join(requesters_path,file)
		if _.isObject(m) and _.isString(m.protocol) and _.isFunction(m.request)
			requesters[m.protocol] = m.request
		else console.log "INFO: invalid requester detected into external_service_manager"
	catch e
		console.log "INFO: failed to load a service requester into external_service_manager"

#@service = object
#@auth = {user:login, password:string}
#@args = {key:value}
module.exports = (service,auth,args,cb)->
	required_args = _.keys service[alias.params]

	# check if all requirements are met to use the service
	if _.filter(_.keys(args),(item)->required_args.indexOf(item)!=-1)?.length != required_args.length
		return cb "Bad arguments",null
	if service[alias.auth] == 1 and auth == null
		return cb "Missing credentials",null

	#define service parameters
	uri = service[alias.uri]
	method = service[alias.method]
	if method.indexOf(':')
		# method is in fact protocol:method so we have to parse it
		parsed = method.split(":")
		if parsed.length == 2
			protocol = parsed[0]
			method = parsed[1]
		else
			return cb "Wrong service method",null
	else
		protocol = method
		method = null

	_r = requesters[protocol]
	if _.isFunction(_r)
		_r uri,method,args,{auth:auth},cb
	else
		return cb "Protocol not supported",null
