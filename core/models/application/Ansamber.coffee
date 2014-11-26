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
	and customEventEmitter (Sequelize.Utils.CustomEventEmitter) to generate new promise
###
_placesHelpers = 
	addAnsamber:(ansamber_data,aliases,options)->
		options= options ? {}
		_= @Sequelize.Utils._
		return new @Sequelize.Utils.CustomEventEmitter (emitter)=>
			@models.self.create(ansamber_data,options)
			.proxy(emitter,{events:['error']})
			.success (ansamber)=>
				qChainer = new @Sequelize.Utils.QueryChainer()
				_.each aliases,(alias)=>
					_.extend alias,{ansamber_id:ansamber.id}
					qChainer.add(@models.ansamber_alias,'create',[alias,options])
				qChainer.runSerially({skipOnError:false})
				.success (results)->
					if options.raw==true
						results = _.map results,(item)->item.values
						ansamber = ansamber.values
					ansamber.aliases = results
					emitter.emit 'success',ansamber
				.error (err)->emitter.emit('error',err)
		.run()
	getAnsamberForPlace:(place_id,uid,options)->
		options= options ? {}
		include_alias = options?.include_alias ? true
		include = []
		if include_alias == true
			include.push {model:@models.ansamber_alias,required:false,where:{default_alias:true},as:'aliases'}
		where =
			uid:uid
			place_id:place_id
		@models.ansamber.find({where:where,include:include},options)

	getAnsambersForPlace:(place_id,options)->
		options= {} if !options
		include = [
			{model:@models.ansamber_alias,required:false,where:{default_alias:true},as:'aliases'}
		]
		where =
			place_id:place_id
		if options?.include_removed != true
			where.status = ne:"removed"
		@models.ansamber.findAll({where:where,include:include},options)
	getPlacesForAnsamber:(uid,options)->
		options = {} if !options
		include = [
			{model:@models.place,required:true,where:{status:'validated'}}
		]
		@models.ansamber.findAll({where:{uid:uid},include:include},options)
module.exports = (register,DataTypes)->
	register 'ansamber',
		id:
			type:DataTypes.INTEGER
			primaryKey:true
			autoIncrement:true
		uid:
			type:DataTypes.STRING
			allowNull:false
			unique:'compositeIndex'
		place_id:
			type:DataTypes.STRING
			allowNull:false
			references:'places'
			referencesKey:'id'
			onDelete:'cascade'
			onUpdate:'cascade'
			unique:'compositeIndex'
		admin:
			type:DataTypes.BOOLEAN
			allowNull:false
			defaultValue:false
		status: #status of the contact for the corresponding place
			type:DataTypes.ENUM('requested','pending','validated','removed')
			allowNull:false
			validate:
				notNull:true
				isIn:[['pending','requested','validated','removed']]
		request_id: #message_id of the ansamber_add request
			type:DataTypes.STRING
			defaultValue:""
		firstname:
			type:DataTypes.STRING
			defaultValue:""
			allowNull:false
		lastname:
			type:DataTypes.STRING
			defaultValue:""
			allowNull:false
	,{
		associate:(models)->
			@belongsTo models.place,{onDelete:'cascade',onUpdate:'cascade',foreignKey:'place_id'}
			@hasMany models.ansamber_alias,{onDelete:'cascade',onUpdate:'cascade',foreignKey:'ansamber_id',as:'aliases'}
		instanceMethods:
			setAsRemoved:->
				@updateAttributes({
					status:'removed'
				})
			setStatus:(status)->
				@updateAttributes({
					status:status
				})
			getFullName:->
				return "#{@firstname||''} #{@lastname||''}"
		_placesHelpers:_placesHelpers
	}
