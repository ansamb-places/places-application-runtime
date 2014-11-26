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
sanitizer = require('sanitizer')

_require_param = (fieldName, req, res, next) ->
  value = req.param_sanitized fieldName
  if typeof value=='undefined'
    return res.send {err:"parameter "+ fieldName + " is missing"}
  req[fieldName] = value
  next()

_require_query = (fieldName, req, res, next) ->
  value = req.query_sanitized[fieldName]
  if typeof value=='undefined'
    return res.send {err:"parameter "+ fieldName + " is missing"}
  req[fieldName] = value
  next()

_require_field = (fieldName, req, res, next) ->
  value = req.body_sanitized[fieldName]
  if typeof value=='undefined'
    return res.send {err:"field "+ fieldName + " is missing"}
  req[fieldName] = value
  next()

module.exports = 
	require_param : (fieldName, req, res, next) ->
		_require_param(fieldName, req, res, next)

	require_query : (fieldName, req, res, next) ->
		_require_query(fieldName, req, res, next)

	require_field : (fieldName, req, res, next) ->
		_require_field(fieldName, req, res, next)

	require_place_name : (req,res,next)->
		_require_query("place_name", req, res, next)

	require_place_id : (req,res,next)->
		_require_param("place_id", req, res, next)

	require_ansamber_id : (req,res,next)->
		_require_param("ansamber_id", req, res, next)

	require_uid : (req,res,next)->
		_require_param("uid", req, res, next)

	require_field_id : (req, res, next) ->
		_require_field("id",req,res,next)

	require_field_uid : (req, res, next) ->
		_require_field("uid",req,res,next)

	require_field_alias : (req, res, next) ->
		_require_field("alias",req,res,next)

	require_field_type : (req, res, next) ->
		_require_field("type",req,res,next)

	require_field_name : (req, res, next) ->
		_require_field("name",req,res,next)

	require_status : (req,res,next) ->
		_require_param("status", req, res, next)

	###
		this middleware will add the following on the request object:
		- req.body_sanitized.${field_name}  # return a sanitized clone of req.body.${field_name}
		- req.query_sanitized.${field_name} # return a sanitized clone of req.query.${field_name}
		- req.sanitize(objOrValue)			# santize a given value or object
	###
	xss_sanitizer : ->
		(req,res,next)->
			req.body_sanitized = {}
			req.query_sanitized = {}
			addProperty = (obj,value,key)->
				# defineProperty allow to run the sanitize computation on demand
				Object.defineProperty obj,key,{
					get:->
						if typeof value == "string"
							return sanitizer.sanitize value
						else
							return value
				}
			_.each req.body,addProperty.bind(null,req.body_sanitized)
			_.each req.query,addProperty.bind(null,req.query_sanitized)
			req.param_sanitized = (paramName)->
				p = req.param(paramName)
				if _.isString(p)
					return sanitizer.sanitize p
				else
					return p

			# also add an helper to sanitize everything at once
			req.sanitize = (objOrValue)->
				if _.isObject(objOrValue)
					result = {}
					_.each objOrValue,(value,key)->
						if typeof value == "string"
							result[key] = sanitizer.sanitize value
						else
							result[key] = value
					return result
				else
					return sanitizer.sanitize objOrValue
			next()
