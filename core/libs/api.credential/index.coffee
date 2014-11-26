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
{EventEmitter} = require 'events'
async = require 'async'

module.exports = (options,imports,register)->
	protocol_builder = imports["protocol.builder"]
	db_manager = imports.database_manager
	server = imports.server
	express = server.app
	getMainDatabase = (cb)->
		db_manager.getApplicationDatabase cb

	api = new EventEmitter
	_.extend api,
		get_credential:(service, cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.credential.find({where:{service: service}}).done (err,credential)->
						callback err,main_db,credential
				(main_db,credential,callback)->
					need_network_fetch = false
					if credential == null
						need_network_fetch = true
					else if new Date(credential.expiration_time) <= new Date()
						need_network_fetch = true
						credential.destroy()
					if need_network_fetch == true
						api.generate_credential service,(err,credentials)->
							callback err,credentials,true
					else
						callback null,credentials,false
				(credential,to_save,callback)->
					if credential == null
						callback "No credential retrieved",null
					else
						if to_save == true
							api.save_credential service,credential,callback
						else
							callback null,credential
			],(err,final_credential)->
				err = err.message if err?.message
				return cb err,null if err?
				credential = final_credential.toJSON()
				credential.url = credential.url.split(',') if credential.url.indexOf(',') != -1
				cb null,credential
		save_credential:(service, credential)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					credential.service = service
					credential.url = credential.url.join(',') if _.isArray(url)
					# TODO the following calculation is wrong (we don't receive a timeout)
					credential.expiration_time = new Date((new Date).getTime()+credential.timeout*1000)
					main_db.models.global.credential.create(credential).done callback
			],cb

		generate_credential:(service, cb)->
			protocol_builder.account.generateCredentialRequest({service: service}).send {timeout:15000},(err,reply)->
				return cb err,null if err?
				if reply.code != 200
					_err = reply.desc || 'unknown error'
					data = null
				else
					_err = null
					data = reply.data
				cb _err, data

		extend_credential:(service, options, cb)->
			data = 
				service:service
				username: options.username || ""
				password: options.password || ""
			protocol_builder.account.extendCredential(data).send (err,reply)->
				return cb err,null if err?
				if reply.code != 200
					_err = reply.desc || 'unknown error'
					data = null
				else
					_err = null
					data = reply.data
				cb _err, data

		extend_credential_with_storage:(service,cb)->
			async.waterfall [
				(callback)->
					getMainDatabase callback
				(main_db,callback)->
					main_db.models.global.credential.find({where:{service: service}}).done callback
				(credential,callback)->
					if credential == null
						return callback "No credential found for this service",null
					protocol_builder.account.extendCredential(credential.toJSON()).send (err,reply)->
						return callback err,null if err?
						if reply.code == 200
							callback null,reply.data,credential
						else
							callback reply.desc,null
				(new_credential,db_object,callback)->
					if new_credential == null
						return callback "Unable to retrieve new credentials",null
					else
						_.extend db_object,new_credential
						db_object.save().done (err)->
							callback err,db_object.toJSON()
			],(err,new_credential)->
				cb err.message||err,new_credential

	#http api definition
	prefix = server.url_prefix.core_api+'/credential'
	express.get "#{prefix}/:service",(req,res)->
		service = req.param('service')
		api.generate_credential service, (err, data)->
			res.send {err:err,data:data}

	express.get "#{prefix}/extend/:service",(req,res)->
		service = req.param('service')
		options =
			username:req.query.username || ""
			password:req.query.password || ""
		api.extend_credential service, options, (err, data)->
			res.send {err:err,data:data}

	register null,{"api.credential":api}