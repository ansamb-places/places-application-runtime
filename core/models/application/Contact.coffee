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

### CUSTOM PLACES METHOD
each of the following methods will have the following runtime context:
this = {Sequelieze:Sequelize module object,models:Models defined for the parent database}
Having access to the whole list of database models here allow to define high level methods

Sequelize also exposes some helpers like lodash (Sequelize.Utils._) 
	and customEventEmitter (equelize.Utils.CustomEventEmitter) to generate new promise
###
_placesHelpers = 
	### CONTACT RELATED HELPERS ###
	#this method will return ansambers which belongs to the user contact list
	getApplicationContacts:(options)->
		options ?= {}
		options.where ?= {}  #where filter on contact table
		options.options ?= null #sequelize options
		include = [
			{model:@models.contact_alias,required:false,where:{default_alias:true},as:'aliases'}
		]
		if options.include_removed != true
			# options.where.status ?= {}
			if typeof options.where.status != 'undefined'
				options.where = @Sequelize.and(options.where, {status:{ne:'removed'}})
			else 
				options.where.status = {ne :'removed'}
		return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
			@models.contact.findAll({where:options.where,include:include},options.options)
			.proxy(emitter,{events:['error']})
			.success (result)=>
				@Sequelize.Utils._.each result,(item)->
					item.aliases = null if item?.aliases?.id == null
				emitter.emit 'success',result
		.run()
	getContactByUid:(uid,options)->
		_= @Sequelize.Utils._
		options ?= {}
		options.include ?= []
		options.where ?= {}
		include = [
			{model:@models.contact_alias,required:false,where:{default_alias:true},as:'aliases'}
		].concat(options.include)
		where = _.extend {uid:uid},options.where
		if options.include_removed != true
			where.status = {ne:'removed'}
		return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
			@models.contact.find({where:where,include:include},options)
			.proxy(emitter,{events:['error']})
			.success (result)=>
				result.aliases = null if result?.aliases?.id == null
				emitter.emit 'success',result
		.run()
	addContact:(contact_data,aliases,options)->
		_= @Sequelize.Utils._
		return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
			qChainer = new @Sequelize.Utils.QueryChainer()
			.add(@models.self,'findOrCreate',[{uid:contact_data.uid},contact_data,options])
			_.each aliases,(alias)=>
				_.extend alias,{contact_uid:contact_data.uid}
				qChainer.add(@models.contact_alias,'create',[alias,options])
			qChainer.runSerially({skipOnError:true})
			.success (results)->
				if options.raw==true
					results = _.map results,(item)->item.values
				results[0].aliases = results.slice(1,results.length)
				emitter.emit 'success',results[0]
			.error (err)->emitter.emit('error',err)
		.run()

module.exports = (register,DataTypes)->
	register 'contact',
		uid:
			type:DataTypes.STRING
			allowNull:false
			primaryKey:true
			validate:
				notEmpty:true
		request_id: #used to save the message_id of an add request (required for the reply)
			type:DataTypes.STRING
			allowNull:true
		message:
			type:DataTypes.TEXT
			allowNull:true
			defaultValue:""
		firstname:
			type:DataTypes.STRING
			defaultValue:""
		lastname:
			type:DataTypes.STRING
			defaultValue:""
		password:
			type:DataTypes.STRING
			defaultValue:""
		status:
			type:DataTypes.ENUM('pending','requested','validated','later','removed')
			allowNull:false
			validate:
				notNull:true
				isIn:[['pending','requested','validated','later','removed']]
	,{
		associate:(models)->
			@hasMany models.place,{as:'MyPlaces',foreignKey:'owner_uid'}
			@hasMany models.contact_alias,{foreignKey:'contact_uid',onDelete:'cascade',onUpdate:'cascade',as:'aliases'}
		instanceMethods:
			setAsRemoved:->
				@updateAttributes({
					status:'removed'
				})
		_placesHelpers: _placesHelpers
	}