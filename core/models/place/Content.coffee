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
	register 'content',
		id:
			type:DataTypes.STRING
			allowNull:false
			primaryKey:true
			validate:
				notEmpty:true
		content_type:
			type:DataTypes.STRING
			allowNull:false
			validate:
				notNull:true
				notEmpty:true
		ref_content:
			type:DataTypes.STRING
			allowNull:true
			defaultValue:null
		# attributes required for synchronization
		date:
			type:DataTypes.DATE
			defaultValue:0
		mergeable:
			type:DataTypes.BOOLEAN
			defaultValue:false
		rev:
			type:DataTypes.STRING
			defaultValue:null
		sync_field: #this field will store a serialized document with the modification date of each data field
			type:DataTypes.TEXT
			defaultValue:null
		synced:
			type:DataTypes.BOOLEAN
			defaultValue:false
		#end of synchronization attributes
		downloadable:
			type:DataTypes.BOOLEAN
			defaultValue:false
		downloaded:
			type:DataTypes.BOOLEAN
			defaultValue:true
		uploaded:
			type:DataTypes.BOOLEAN
			defaultValue:false
		uri:
			type:DataTypes.TEXT
			allowNull:true
			defaultValue:null
			validate:
				isEven:(value)->
					#TODO create regular expression to validate uri
					return true
		status:
			type:DataTypes.STRING
			allowNull:true
			defaultValue:null
		likes:
			type:DataTypes.BIGINT
			defaultValue:0
		owner:
			type:DataTypes.STRING
			defaultValue:null
			validate:
				isEven:(value)->
					#TODO create regexp to validate UID
					return true
		read:
			type:DataTypes.BOOLEAN
			defaultValue:1
			allowNull:false
		#this field is used to store the application children type when the document is a collection
		_app_children_type:
			type:DataTypes.STRING
			allowNull:true
			defaultValue:null
		#used to store the serialized json data if no applications is able to manage the content
		_raw_data:
			type:DataTypes.TEXT
			allowNull:true
			defaultValue:null
		#used to store content extra datas (ex: informations sended for files inside the content document)
		ansamb_extras:
			type:DataTypes.TEXT
			allowNull:true
			defaultValue:null
	,{
		associate:(models)->
			#@hasMany(models.comment,{onDelete:'cascade',onUpdate:'cascade'})
		classMethods:
			getUnreadCount:->
				@count {where:{read:false}}
	}
