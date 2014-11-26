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
	addAliases:(id,aliases,options)->
		options= options ? {}
		_= @Sequelize.Utils._
		addAliasSkippingError=(_alias,options)=>
			options= options ? {}
			return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
				@models.ansamber_alias.create(_alias,options)
				.success (result)->
					result = result.values if options.raw==true
					emitter.emit 'success',result
				.error (err)->
					emitter.emit 'success',err
			.run()
		return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
			qChainer = new @Sequelize.Utils.QueryChainer()
			_.each aliases,(alias)=>
				_.extend alias,{ansamber_id:id}
				qChainer.add(addAliasSkippingError(alias,options))
			qChainer.run()
			.success (results)->
				emitter.emit 'success',results
		.run()
module.exports = (register,DataTypes)->
	register 'ansamber_alias',
		id:
			type:DataTypes.INTEGER
			primaryKey:true
			autoIncrement:true
		ansamber_id:
			type:DataTypes.INTEGER
			allowNull:false
			unique:'compositeIndex'
			references:'ansambers'
			referencesKey:'id'
			onDelete:'cascade'
			onUpdate:'cascade'
		alias:
			type:DataTypes.STRING
			allowNull:false
			defaultValue:''
			unique:'compositeIndex'
		type: #status of the contact for the corresponding place
			type:DataTypes.STRING
			allowNull:false
			defaultValue:''
			unique:'compositeIndex'
		default_alias: #message_id of the ansamber_add request
			type:DataTypes.BOOLEAN
			defaultValue:false
			allowNull:false
	,{
		associate:(models)->
			@belongsTo models.ansamber,{onDelete:'cascade',onUpdate:'cascade',foreignKey:'ansamber_id'}
		_placesHelpers: _placesHelpers
	}