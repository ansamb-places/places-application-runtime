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
passwordHash = require './passwordHash'
_ = require 'underscore'
{EventEmitter} = require 'events'
async = require 'async'
networkMsgHelper = require '../../common_lib/NetworkMessageHelper'

code = 
	accepted:202
	bad_request:400
	conflict:409 #account already exists
	pending:460 #account already created and awaiting validation
	ok:200
	not_found:404

messages =
	'202':'Account created'
	'400':'Bad request'
	'409':'An account already exists'
	'460':'The request for this account is waiting for validation'
	'200':'Account validated'
	'404':'The registration request was not found'

status =
	verified:'validated'
	unverified:'invalid'
	unregistered:'unregistered'
	conflict:'conflict'

module.exports = (options,imports,register)->
	protocol_builder = imports["protocol.builder"]
	com_layer = imports.communication_layer
	external_service_manager = imports["external_service_manager"]
	events = imports.events.namespaced("account")
	db_manager = imports.database_manager
	server = imports.server
	express = server.app

	# store the choosen user language if no account is defined
	userLang = null
	acceptedLanguages = ['en_US','fr_FR']

	api = new EventEmitter
	_.extend api,
		STATUS:status
		registration_status:status.unverified
		account : null #store the account document (uid, firstname, ...)
		hashed_password:null #will store the hashed password of the user
		logged:false
		defaultUserLang:"en_US"
		#data = {informations required to register}
		#alias_options = {field_name:string,type:(email|tel|...)}
		setHashedPassword:(hashed_pwd)->
			@hashed_password = hashed_pwd
		getHashedPassword:->
			return @hashed_password
		register:(data,alias_options,cb)->
			if _.isUndefined cb
				cb = alias_options
				alias_options = null
			# hashed password used to request services and remote APIs
			local_pwd_obj = passwordHash.generateSaltAndHashPasswordSync(data.password)
			remote_pwd_obj = passwordHash.generateSaltAndHashPasswordSync(data.password)
			#we save the hashed password intended for the accout hoster in order to use remote APIs later
			@setHashedPassword remote_pwd_obj.value
			#hash the password twice, once for the kernel and once for the server
			data.password =
				local:local_pwd_obj
				remote:remote_pwd_obj
			if not alias_options or not alias_options.field_name or not alias_options.type
				return cb "Alias options are missing"
			if data[alias_options.field_name] and typeof data[alias_options.field_name] == "string"
				alias = data[alias_options.field_name]
				type = alias_options.type
				delete data[alias_options.field_name]
				data.aliases = [{
					alias:alias
					type:type
				}]
			else
				return cb "Wrong alias"
			# inject userLang
			data.lang = userLang || @defaultUserLang
			protocol_builder.account.registerRequest(data).send {timeout:35000},(err,reply)->
				api._handleRegisterReply err,reply,cb
		accountRegistrationRetry:(cb)->
			protocol_builder.account.registrationRetry().send {timeout:10000},(err,reply)->
				api._handleRegisterReply err,reply,cb
		_handleRegisterReply:(err,reply,cb)->
			if err?
				console.error err
				return cb err
			_code = reply.code
			if _code == code.accepted
				console.log "Account registration accepted"
				@registration_status = status.unverified
				#save the profile document into memory
				api.account = reply.data.account.data
				@logged = true
				external_service_manager.setAuthCredentials @getUid(),@getHashedPassword()
				external_service_manager.setDescriptor reply.data.ah_services
				cb(null,api.account)
			else
				console.error "Error:receive code #{reply.code}"
				message_text = reply?.data?.msg || messages[''+_code] || "Unknwon error (code #{_code})"
				error = new Error(message_text)
				error.code = _code
				cb(error,{error_code:_code})
		login:(alias,clear_password,cb)->
			return cb null,true if @isLogged()
			@getAccount (err,account)=>
				return cb err if err?
				return cb "No account" if account == null
				password_match = passwordHash.hashPassword(clear_password,account.password.local.salt) == account.password.local.value
				if password_match and _.where(@getAllAliases(),alias).length > 0
					@setHashedPassword passwordHash.hashPassword(clear_password,account.password.ah.salt)
					external_service_manager.setAuthCredentials @getUid(),@getHashedPassword()
					@logged = true
					cb null,true
				else
					cb null,false
		isLogged:->
			return @logged
		resend_code:(clear_password,cb)->
			if  typeof clear_password != "string" or clear_password.length==0
				return cb and cb "Invalid password"
			async.waterfall [
				(callback)->
					api.getAccount callback
				(account,callback)->
					return callback "No account" if account==null or _.isUndefined account
					args = {}
					aliases = api.getAllAliases()
					if _.isArray(aliases)
						if aliases.length > 0
							args.a = networkMsgHelper.aliasObjectToAnsambFormat(aliases[0])
						else
							return cb "No aliase defined for this account"
					else
						console.log "[WARNING] account.aliases is not an object"
						return cb "No aliase defined for this account"
					auth =
						login:api.getUid()
						password:passwordHash.hashPassword(clear_password,api.account?.password?.ah?.salt)
					external_service_manager.requestService "resend_code",args,{auth:auth},(err,reply)=>
						callback null,err,{code:reply?.http_code}
			],cb
		resetAccount:(cb)->
			protocol_builder.account.accountReset().send (err,reply)=>
				if err?
					cb err,null
				else
					if reply.code == 200
						@logged = false
						@account = null
						@setHashedPassword null
						cb null,{code:reply.code}
					else
						cb reply.desc||"Unknown error",{code:reply.code}
		getUid:->
			if @account==null
				console.log "No UID defined"
				return null
			else
				return @account?.uid
		getFirstAlias:->
			if @account==null
				console.error("No account defined")
				return null
			return null if not @account.aliases
			keys = Object.keys(@account.aliases)
			return null if keys.length == 0
			return @account.aliases[keys[0]]
		getAllAliases:->
			if @account==null
				console.error("No account defined")
				return null
			if @account.aliases
				return _.values @account.aliases
			else
				return null
		getUidAsync:(cb)->
			if @account == null
				api.getAccount (err,account)->
					cb err,account?.uid
			else
				cb null,@account?.uid
		getAccount:(options,cb)->
			if _.isUndefined cb
				cb = options
				options = {force:false}
			if options?.force != true and @account?
				cb null,@account
			else
				#profile is the content_id which refers to the user profile document
				protocol_builder.account.getRequest().send (err,reply)=>
					if err==null
						if reply.data.content != null and reply.data.content != 'undefined'
							@account = reply.data.content.data
						else
							@account = null
					cb(err,@account)
		getAccountStatus:(cb)->
			@getAccount (err,account)=>
				return cb err,null if err?
				if account == null
					cb(null,status.unregistered)
				else
					cb(null,account?.status)
					if account.status == status.verified
						@emit "account:checked"
		validate_account:->
			if @registration_status!="registered"
				@registration_status="registered"
				@emit "registered"
				@emit "account:checked"
				events.emit "validated"
				if @isLogged() == true
					server.stepManager.goToStep('main_app',{validate_current:true})
				else
					server.stepManager.goToStep('login',{validate_current:true})
		getUDID:(cb)->
			protocol_builder.account.getUDID().send (err,reply)->
				cb err,reply?.data?.udid
		getUserLanguage:->
			return userLang || @account?.lang || @defaultUserLang
		setUserLanguage:(lang)->
			if acceptedLanguages.indexOf(lang) == -1
				return false
			else
				userLang = lang
				return true

	#http api definition
	prefix = server.url_prefix.core_api+'/account'
	express.get "#{prefix}",(req,res)->
		api.getAccount (err,data)->
			if _.isObject(data)
				data = _.pick data,'uid','aliases','firstname','lastname','status'
			res.send {err:err,data:data}
	express.get "#{prefix}/status",(req,res)->
		api.getAccountStatus (err,status)->
			res.send {err:err,status:status}
	express.get "#{prefix}/uid",(req,res)->
		try
			res.send api.getUid()
		catch e
			res.send null
	express.get "#{prefix}/is_logged",(req,res)->
		res.send {err:null,logged:api.logged}
	express.post "#{prefix}/login/",(req,res)->
		alias =
			alias:req.body.email
			type:"email"
		password = req.body.password
		api.login alias,password,(err,authenticated)->
			res.send {err:err,authenticated:authenticated}

	# ask for the account before publishing the module because we need our own UID
	api.getAccount (err,reply)->
		register null,
			"api.account":api
