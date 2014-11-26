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
fs = require 'fs'
_ = require 'underscore'

module.exports = 
	loadJSONfile:(path)->
		try
			return JSON.parse(fs.readFileSync(path))
		catch e
			return null
	#this function convert version format 'x.x.x' to decimal number for comparaison purpose
	#each element have to belongs to [0-99] (ex:0.1.45) if digit_number==2
	versionToNumber : (version,digit_number)->
		if arguments.length==1
			digit_number=2
		multiplicator = Math.pow(10,digit_number)
		if /([0-9]{1,}\.){2,}\d/.test(version)
			els = version.split('.')
			v = 0
			_.each els,(el,index)->
				v = v + el*Math.pow(multiplicator,els.length-(index+1))
			return v
		return null
	normalized_string:(string)->
	 	return string.replace(/\s/g,"_")