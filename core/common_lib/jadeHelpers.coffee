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
	getFormData:(req,fields,options)->
		return {} if !fields
		form= req?.session?.flash?.form || null
		form= form[0] if _.isArray(form) and form.length>0
		data= {}
		_.each fields,(field)->
			if form?.hasOwnProperty(field)
				data[field]=form[field]
			else 
				data[field]=""
		return data
	buildFlashForm:(req,options)->
		options = {} if !options
		options.omit = [] if !options.omit
		if req and req.flash and _.isFunction(req.flash)
			req.flash 'form',_.omit(req.body,options.omit)