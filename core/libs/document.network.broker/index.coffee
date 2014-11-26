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
util = require 'util'
ps = require '../../common_lib/ProtocolSanitizer'
messageHelper = require '../../common_lib/NetworkMessageHelper'

module.exports = (options,imports,register)->
	content_lib = imports["api.place.content"]
	place_lib = imports["api.place"]
	ansamber_lib = imports["api.place.ansamber"]
	application_registery = imports["application.registery"]
	account_lib = imports["api.account"]

	#this helper is required to merge data and clear_data fields
	mergeData = (doc)->
		#TODO remove this ugly thing
		doc.data = null if doc.data=="undefined"
		doc.clear_data = null if doc.clear_data=="undefined"
		doc.data = doc.data||{}
		_.extend doc.data,doc.clear_data

	api = {}
	api.handleDocument = (protocol,method,document)->
		return console.error("document is undefined or null") if _.isUndefined(document) or document==null
		mergeData(document)
		content_type = document.content_type
		switch content_type
			when "ansamber"
				#we don't save documents related to ourself
				if document.data.uid == account_lib.getUid()
					return console.log "ignoring document for #{document.data.uid}"
				ansamber_option =
					status:'validated'
					firstname:document.data?.firstname||""
					lastname:document.data?.lastname||""
				ansamber_option.aliases = messageHelper.aliasesDbArrayAdapter(document.data.aliases,{first_as_default:true})
				ansamber_lib._createOrUpdateAnsamber document.dpl,document.data.uid,ansamber_option,(err,ansamber)->
					console.log err if err?
					#TODO manage errors
			when "place_settings"
				place_lib.updatePlaceSettings document.data,(err)->
					console.log err if err?
			else
				if application_registery.isContentTypeManaged(content_type)
					owner = document.src
					if owner == account_lib.getUid()
						owner = null
					content_options =
						id:document.content_id
						date:new Date(document.date)
						rev:document.rev
						content_type:document.content_type
						owner:owner
						emit_network:false
						uploaded:true
						read:false
						ansamb_extras:document.data?.ansamb_extras || null
						origin_protocol:protocol
					fun = null
					if protocol=="sync" or protocol=="content"
						content_options.merge_algo= 'latest_win'
						fun = content_lib.createOrUpdateContent
						keys= null 
						if _.isObject document.clear_data
							keys= _.keys(document.clear_data)
						data = ps.sanitizeDataField(document.data,keys)
						fun.call content_lib,document.dpl,content_options,data,(err,content,data)->
							console.log err if err?
					else
						console.log "Protocol unrecognized"
				else
					console.error "Content-type #{document.content_type} is not managed"

	register null,{"document.network.broker":api}