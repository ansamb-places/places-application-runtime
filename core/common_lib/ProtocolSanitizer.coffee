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
omit_data_fields = ['ansamb_extras']
omit_protocol_headers = ['ansamb_extras','mergeable','rev','sync_field','_app_children_type','_raw_data']
exports = module.exports = {
	#used by document broker to remove fields parsed by the framework and not by applications
	sanitizeDataField:(data,omit_fields)->
		omit_fields = [] if not _.isArray(omit_fields)
		omit_keys = _.union omit_data_fields,omit_fields
		return _.omit data,omit_keys
	sanitizeProtocolHeader:(header)->
		return _.omit header,omit_protocol_headers
}