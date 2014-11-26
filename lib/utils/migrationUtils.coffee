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
fs = require 'fs'
regexp = /^((\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}))-migration-from-((?:\d\.){2,}\d)-to-((?:\d\.){2,}\d)/

# migration filename need to respect the following format:
# YYYYMMDDHHmmss-migration-from-x.x.x-to-x.x.x.js

exports.parseFileName = parseFileName = (name)->
	if name==null
		return null
	match = name.match(regexp)
	unless match?
		return null
	return {
		from:match[8]
		to:match[9]
	}
exports.getListMigrationFiles = (dir)->
	return _.filter fs.readdirSync(dir),(el)->
		regexp.test el
exports.getMigrationFileFromVersion = (list,version)->
	result = _.filter list,(el)->
		v = parseFileName el
		if v==null
			return false
		return v.from==version
	return if result.length then result[0] else null