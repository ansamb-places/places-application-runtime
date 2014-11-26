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
module.exports = (register,DataTypes)->
	register 'notification',
		ref:
			type:DataTypes.STRING
			allowNull:true
			defaultValue:null
		place_id:
			type:DataTypes.STRING
			defaultValue:null
			references:'places'
			referencesKey:'id'
			onDelete:'cascade'
			onUpdate:'cascade'
		date:
			type:DataTypes.DATE
			defaultValue:0
			allowNull:false
			validate:
				isDate:true
		data:
			type:DataTypes.TEXT
			defaultValue:''
		tag:
			type:DataTypes.STRING
			allowNull:false
			validate:
				notNull:true
				notEmpty:true
		scope:
			type:DataTypes.STRING
			defaultValue:'*'
		read:
			type:DataTypes.BOOLEAN
			defaultValue:0
	,{
		timestamps:false
		associate:(models)->
			@belongsTo models.place,{foreignKey:'place_id',onUpdate:'cascade',onDelete:'cascade'}
	}