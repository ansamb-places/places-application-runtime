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
define ->
	# Module popping save as system dialog, found in main_layout.jade (.download_hidden_input)
	requireJS = window.require
	window.require = require = window.requireNode
	module = {
		popSaveAs: ()->
			alert "Please use node-webkit"
	}
	if require?
		path = require 'path'
		fs = require 'fs'
		file = ""
		cb = null
		input_button = $('.download_hidden_input')
		home_folder = process.env.HOME || process.env.USERPROFILE
		download_path = path.join home_folder, 'Downloads'
		module = {
			popSaveAs: (filename, callback)->
				file = filename
				cb = callback
				fs.mkdir download_path,(err, made)=>
					input_button.attr 'nwworkingdir', download_path
					if _.isArray(file) && file.length > 1 # Multiple selection
						input_button.attr 'nwsaveas', file[0]+', ...'
						input_button.prop 'nwdirectory'
					else
						input_button.attr 'nwsaveas', file
					input_button.off('change').one 'change',@handleChange
					input_button.click()
			handleChange: (event)->
				val = input_button.val()
				return if val == ''
				dir = path.dirname(val)
				if _.isArray file # Multiple selection
					input_path = dir
				else
					input_path = path.join(dir,file)
				input_button.val ''
				cb input_path
		}
	window.require = requireJS
	return module