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
	requireJS = window.require
	window.require = require = window.requireNode
	module = {
		openInBrowser: (target)->
			console.log "Please use node-webkit"
		openInFinder: (file_path)->
			console.log "Please use node-webkit"
	}
	if require?
		gui = require 'nw.gui'
		module = {
			openInBrowser: (target)->
				target.click (event)->
					event.preventDefault();
					gui.Shell.openExternal target.attr('href')
			openInFinder: (file_path)->
				gui.Shell.showItemInFolder file_path
		}
	window.require = requireJS
	return module