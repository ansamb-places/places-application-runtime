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
define [
	'cs!app'
	'cs!node-webkit/notify'
],(App,nw_notify)->
	lastTimestamp = 0
	App.vent.on 'system:notify', (audio_src)->
		newTimestamp = +new Date()
		if newTimestamp - lastTimestamp < 2000 then silent = true else silent = false
		lastTimestamp = newTimestamp 
		nw_notify.requestAttention true if !silent
		nw_notify.badgeLabel()
		if !silent
			audio_src = audio_src || "/sounds/notify.ogg"
			if $('#audio_el').length == 0
				$audio_el = $("<audio id='audio_el'><source src='#{audio_src}' type='audio/ogg'></audio>")
				$('body').append $audio_el
			else
				$audio_el = $('#audio_el')
			$audio_el[0].load()
			$audio_el[0].play() 
	return null