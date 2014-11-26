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
_placesHelpers =
	addAliases:(uid,aliases,options)->
		options= options ? {}
		_= @Sequelize.Utils._
		addAliasSkippingError=(_alias,options)=>
			options= options ? {}
			return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
				@models.contact_alias.create(_alias,options)
				.success (result)->
					result = result.values if options.raw==true
					emitter.emit 'success',result
				.error (err)->
					emitter.emit 'success',err
			.run()
		return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
			qChainer = new @Sequelize.Utils.QueryChainer()
			_.each aliases,(alias)=>
				_.extend alias,{contact_uid:uid}
				qChainer.add(addAliasSkippingError(alias,options))
			qChainer.run()
			.success (results)->
				emitter.emit 'success',results
		.run()
	# alias example : { alias: 'john@doe.com', type: 'email' }
	isAliasExists:(alias)->
		return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
			@models.self.count({where: alias}).proxy(emitter,{events:['error']}).done (err, count)->
				emitter.emit 'success', count>0
		.run()
	getContactForAlias:(alias,options)->
		options ?= {}
		include = [
			{model:@models.contact,as:'contact',required:true,where:{status:{ne:'removed'}}}
		]
		@models.contact_alias.find({where:alias,include:include},options)

module.exports = (register,DataTypes)->
	register 'contact_alias',
		contact_uid:
			type:DataTypes.STRING
			allowNull:false
			references: 'contacts'
			referencesKey: 'uid'
			onDelete: 'cascade'
			onUpdate: 'cascade'
			unique:"composite_index"
		alias: #used to save the message_id of an add request (required for the reply)
			type:DataTypes.STRING
			allowNull:false
			unique:"composite_index"
		type:
			type:DataTypes.STRING
			allowNull:false
			validate:
				notNull:true
				isIn:[['email','tel']]
			unique:"composite_index"
		default_alias:
			type:DataTypes.BOOLEAN
			defaultValue:false
			allowNull:false
	,{
		associate:(models)->
			@belongsTo models.contact,{as:'contact',foreignKey:'contact_uid',onDelete:'cascade',onUpdate:'cascade'}
		_placesHelpers: _placesHelpers
	}