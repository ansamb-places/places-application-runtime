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
async = require 'async'

#private functions
extractDateFromDocument=(data)->
	date_document = {}
	_.each data,(value,key,list)->
		if value.hasOwnProperty('value') and value.hasOwnProperty('modification_date')
			date_document[key] = value.modification_date
		else if _.isObject value
			tmp = extractDateFromDocument(value)
			date_document[key] = tmp if _.keys(tmp).length > 0 
	return date_document

createFieldTags=(data,sync_date_doc,db_date_doc)->
	new_doc = {}
	_.each data,(value,key,list)->
		if db_date_doc==null or _.isUndefined(db_date_doc)
			if value.hasOwnProperty('value') and value.hasOwnProperty('modification_date')
				new_doc[key] = 
					value:value.value
					tag:if value.value=="" then 'deleted' else 'new'
			else if not _.isObject(value)
				new_doc[key] = 
					value:value
					tag:if value=="" then 'deleted' else 'new'
			else
				new_doc[key] = createFieldTags(value,sync_date_doc[key],null)
		else	#compare dates to know if the field has been updated or created
			if value.hasOwnProperty('modification_date')
				if _.isUndefined db_date_doc[key]
					new_doc[key] = 
						value:value.value
						tag:if value.value=="" then 'deleted' else 'new'
				else
					tag = if db_date_doc[key]<sync_date_doc[key] then 'updated' else 'no-change'
					new_doc[key]=
						value:value.value
						tag:tag
			else if not _.isObject(value)
				new_doc[key]=
					value:value
					tag:if value=="" then 'deleted' else 'new'
			else
				new_doc[key] = createFieldTags(value,sync_date_doc[key],db_date_doc[key])
	return new_doc

class ContentSyncManager
	constructor:(@place_db,@content_lib)->
	#cb(new,doc_with_tags)
	handleSyncMessage:(method,message,cb)->
		content_id = message.content_id
		if method == 'PUT'
			date_document = extractDateFromDocument(message.content)
			@content_lib.getContentById message.dpl,content_id,(err,content)->
				#new document
				if content==null
					final_doc = createFieldTags(message.content,date_document,null)
					@content_lib.addContent message.dpl,message.content_type,content_id,(err,content)->
						@place_db.global.models.sync_data.create({
							content_id:content.id
							date_document:JSON.stringify(date_document)
						}).done (err)->
							cb err,
								created:true
								method:method
								content_id:content_id
								content_model:content
								data:final_doc
				else
					content.getSyncData().done (err,sync_data)->
						throw new Error("no sync data") if sync_data==null
						db_date_doc = JSON.parse(sync_data.date_document)
						final_doc = createFieldTags(message.content,date_document,db_date_doc)
						sync_data.date_document = JSON.stringify(date_document)
						#TODO update content table
						content.last_timestamp = +new Date
						async.parallel [
							(callback)->
								content.save().done callback
							(callback)->
								sync_data.save().done callback
						],(err)->
							cb err,
								created:false
								method:method
								content_model:content
								content_id:content_id
								data:final_doc
		else if method == 'DELETE'
			@content_lib.deleteContent message.dpl,{id:content_id},(err)->
				cb err,
					created:false
					method:method
					content_id:content_id
					data:null

module.exports = ContentSyncManager