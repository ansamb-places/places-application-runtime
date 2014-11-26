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
#this function will allow to validate if an application respect ansamb specifications
_ = require 'underscore'
module.exports = (app_module)->

	validate_properties=(validator,obj)->
		if typeof obj=='undefined'
			if validator?.require == false
				return true
			else
				return false
		if validator.hasOwnProperty('properties')
			for key,attr of validator.properties
				unless validate_properties(attr,obj[key])
					return false
			return true
		else
			return validator.validate(obj) if _.isFunction(validator.validate)
			return true

	validate = (rule,obj)->
		for key,attr of rule
			unless validate_properties(attr,obj[key])
				return false
		return true

	validation = 
			init:
				validate:_.isFunction
			# test:
			# 	require:true
			crud:
				properties:
					create:
						validate:_.isFunction
					read:
						validate:_.isFunction
					update:
						validate:_.isFunction
					delete:
						validate:_.isFunction


	return validate(validation,app_module)