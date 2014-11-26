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
module.exports = 
	errorCatchCb:(errorCb,cb)->
		(err)->
			return errorCb(err) if err?
			cb.apply(null,arguments)
	methodObj:(obj)->
		functions = _.functions obj
		newObj = {}
		newObj[f] = obj[f].bind(obj) for f in functions
		return newObj
	parsePlaceId:(place_id)->
		uuid_separator_index = place_id.indexOf('@')
		return null if uuid_separator_index<=0
		obj = {	
			uuid:null
			owner_uid:null
		}
		if uuid_separator_index!=-1
			obj.uuid = place_id.substr(0,uuid_separator_index) 
			obj.owner_uid = place_id.substr(uuid_separator_index+1)
		else
			obj.uuid = place_id
		return obj
	escapeStrForRegexp : (string)->
		string.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
	parseFileExt:(filename)->
		extException= ['.tar.gz','.tar.bz','.tar.xz']
		ext =_.find extException,(item)->
			extEx = item.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
			regexp= new RegExp(".+?"+extEx)
			match = regexp.exec(filename)
			return true if match?
			return false
		return ext if ext
		return /.+?(\.[^.]*$|$)/.exec(filename)[1]
	# @req is the express request object 
	isPlacesTestSuite:(req)->
		if req?.headers and typeof req.headers['user-agent'] == "string"
			return req.headers['user-agent'].indexOf("PlacesTestSuite") == 0
		else
			return false