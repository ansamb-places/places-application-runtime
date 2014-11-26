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
common =
	ver:1
	protocol:'account'
	dst:'ansamb'
	spl:'ansamb.account'
	dpl:'ansamb.account'
module.exports = 
	name:'account'
	api:
		getRequest:->
			message = _.extend
				method:"GET"
			,common
		registerRequest:(data)->
			aliases = {}
			if data.aliases
				_.each data.aliases,(alias)->
					aliases["#{alias.type}/#{alias.alias}"] = alias
			message = _.extend
				method:"REGISTER"
				data:
					aliases:aliases
					password:
						local:data.password.local
						ah:data.password.remote
					lang:data.lang
			,common
			message.data.firstname = data.firstname if data.firstname
			message.data.lastname = data.lastname if data.lastname
			return message
		resendCodeRequest:(data)->
			return _.extend
				method:"RESEND_CODE"
				data:
					password:data.password
			,common
		generateCredentialRequest:(data)->
			return _.extend
				method:"GEN_CRED"
				data:
					service:data.service
			,common
		extendCredential:(data)->
			return _.extend
				method:"EXT_CRED"
				data:
					service:data.service
					username:data.username
					password:data.password
			,common
		accountReset:->
			return _.extend
				method:"RESET"
			,common
		registrationRetry:->
			return _.extend
				method:"RETRY"
			,common
		getUDID:->
			return _.extend
				method:"GET_UDID"
			,common
	schema:
		registerRequest:
			$schema:"http://json-schema.org/draft-04/schema#"
			type:"object"
			properties:
				data:
					type:"object"
					properties:
						aliases:
							type:"object"
							patternProperties:
								".+\/.+":
									type:"object"
									properties:
										alias:{type:"string"}
										type:{type:"string"}
									required:['alias','type']
						firstname:{type:"string"}
						lastname:{type:"string"}
						password:
							type:"object"
							properties:
								local:
									type:"object"
									properties:
										algo:{type:"string"}
										salt:{type:"string"}
										value:{type:"string"}
									require:["algo","salt","value"]
								ah:
									type:"object"
									properties:
										algo:{type:"string"}
										salt:{type:"string"}
										value:{type:"string"}
									require:["algo","salt","value"]
							required:["local","ah"]
						lang:{type:"string"}
					required:["aliases","password","firstname","lastname"]
			required:["data"]
		resendCodeRequest:
			$schema:"http://json-schema.org/draft-04/schema#"
			type:"object"
			properties:
				data:
					type:"object"
					properties:
						password:{type:"string"}
					required:["password"]
			required:["data"]
