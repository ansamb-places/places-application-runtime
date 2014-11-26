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

_placesHelpers = 
	#options = Sequelize options
	getByid:(place_id,options)->
		include = [
			{model:@models.ansamber,include:[{model:@models.ansamber_alias,as:"aliases",required:false,where:{default_alias:true}}]},
			{model:@models.contact,as:'owner'}
		]
		return @models.self.find({where:{id:place_id},include:include},options)
	getAll:(options)->
		options.where ?= {} #where filter
		options.options ?= {} #sequelize options
		return @models.self.findAll({where:options.where,include:[{model:@models.ansamber},{model:@models.contact,as:'owner'}]},options.options)

module.exports = (register, DataTypes)->
	register 'place',
		#name is the ansamb name (<nature>.<name>@<owner_uid>)
		id:
			type:DataTypes.STRING
			primaryKey:true
			validate:
				isEven:(value)->
					regexp = /^[^\s]*(@[^\s]*)?$/
					unless regexp.test(value)
						throw new Error("Invalid place name format")
		name:
			type:DataTypes.STRING
			defaultValue:""
		desc:
			type:DataTypes.TEXT
			defaultValue:null
		type:
			type:DataTypes.STRING
			validate:
				notNull:true
				isIn: [['share', 'conversation']]
		owner_uid:
			type:DataTypes.STRING
			references:'contacts'
			referencesKey:'uid'
			onDelete:'restrict'
			onUpdate:'cascade'
			defaultValue:null
		creation_date:
			type:DataTypes.DATE
			validate:
				notNull:true
		status: #allow to know the state of the place (pending | validated | disabled)
			type:DataTypes.STRING
			defaultValue:"pending"
			allowNull:false
		# network_synced could be 0, 1 or 2
		# 0: no yet synced
		# 1: synced but not ready (missings documents)
		# 2: synced and ready
		network_synced: #define if the place has been created on the kernel
			type:DataTypes.INTEGER.UNSIGNED
			defaultValue:0
			allowNull:false
		network_request_id: #message id of the kernel notification message
			type:DataTypes.STRING
			defaultValue:null
			allowNull:true
		add_request_id: #message id of the add request
			type:DataTypes.STRING
			defaultValue:null
			allowNull:true
		last_sync_date:
			type:DataTypes.DATE
			allowNull:true
			default:null
		auto_sync: #used to know if content sync have to be done automatically
			type:DataTypes.BOOLEAN
			defaultValue:true
			allowNull:false
		auto_download: #used to know if file have to be downloaded automatically
			type:DataTypes.BOOLEAN
			defaultValue:true
			allowNull:false
	,{
		associate:(models)->
			@hasMany models.notification,{foreignKey:'place_id',onDelete:'cascade',onUpdate:'cascade'}
			@hasMany models.protocol,{onDelete:'cascade',onUpdate:'cascade',through:models.placeProtocolJoin}
			@hasMany models.ansamber,{onDelete:'cascade',onUpdate:'cascade',foreignKey:'place_id'}
			@belongsTo models.contact,{as:'owner',foreignKey:'owner_uid',onDelete:'restrict',onUpdate:'cascade'}
		instanceMethods: {
			isDisabled:->
				return @status == "disabled"
			isSyncable:->
				return @status == "validated"
			isNetworkSynced:->
				return @network_synced == 2
			isMine:->
				return true if @owner_uid == null
				return false
		}
		_placesHelpers: _placesHelpers
		hooks:
			beforeValidate: (place, done) ->
				place.name = _.escape place.name
				place.desc = _.escape place.desc
				done()
	}