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


helpers =
	aliasesDbArrayAdapter:(network_aliases,options)->
		options = options ? {}
		alias_index = 0
		if not _.isObject(network_aliases)
			return []
		_.map network_aliases,(alias,key)->
			if options.first_as_default == true and alias_index == 0
				alias.default_alias = true
			alias_index++
			return alias
	aliasObjectToAnsambFormat:(alias_obj)->
		if not _.isObject(alias_obj) or not alias_obj.alias or not alias_obj.type
			return null
		else
			return "#{alias_obj.type}/#{alias_obj.alias}"

exports = module.exports = helpers