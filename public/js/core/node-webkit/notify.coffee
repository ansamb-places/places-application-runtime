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
	# System-wide notifications
	requireJS = window.require
	window.require = require = window.requireNode
	module = {
		newNotifications: 0
		badgeLabel:->
			console.log "Please use node-webkit"
		requestAttention:->
			console.log "Please use node-webkit"
	}
	if require?
		gui = require 'nw.gui'
		win = gui.Window.get()
		handleFocus = ->
			module.focused = true
			win.setBadgeLabel ""
			module.newNotifications = 0
		handleBlur = ->
			module.focused = false
			module.newNotifications = 0
		module = {
			newNotifications: 0
			focused: true
			badgeLabel:()->
				if !module.focused
					module.newNotifications++
					win.setBadgeLabel module.newNotifications
			requestAttention:(count)->
				win.requestAttention count || true
		}
		win.window.addEventListener 'focus', ->
			handleFocus()
		win.on 'focus', ->
			handleFocus()
		win.window.addEventListener 'blur', ->
			handleBlur()
		win.on 'blur', ->
			handleBlur()
	window.require = requireJS
	return module