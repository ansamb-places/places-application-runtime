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

#clone the fs object (only functions)
new_object = {}
for name,f of fs
	new_object[name] = f

# redefine readdir and readdirSync to escape MAC .DS_Store special file
new_object.readdirSync = (path)->
	files = fs.readdirSync(path)
	if _.isArray(files)
		return _.without(files,'.DS_Store')
	else
		return files
new_object.readdir = (path,cb)->
	fs.readdir path,(err,files)->
		if _.isArray(files)
			files = _.without(files,'.DS_Store')
		cb err,files
module.exports = new_object