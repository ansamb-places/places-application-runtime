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
	register 'file',
		name:
			type:DataTypes.STRING
			defaultValue: ""
		filesize:
			type:DataTypes.BIGINT
			defaultValue: 0
		mime_type:
			type:DataTypes.STRING
			defaultValue:null
			allowNull:true
		mdate:
			type:DataTypes.DATE
			defaultValue: 0
		path:
			type:DataTypes.STRING
			defaultValue: ""
		relative_path:
			type:DataTypes.STRING
			defaultValue: ""
		extra:
			type:DataTypes.STRING
			defaultValue: ""
	,{
		associate:(models)->
			@belongsTo(models.global.content,{onDelete:'cascade',onUpdate:'cascade',as:'Content'})
			#models defined by the application are accessible through models.myModels
	}