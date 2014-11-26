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
define ['jquery'],($)->
	initialize = ->
		progressBar=0
		setInterval ->
			progressBar = (progressBar+10)%110;
			$('#progressbar').css('width',progressBar+'%')
		,250
		#window.step is intended to be defined globally into the web page
		if typeof window.step == "string"
			$.ajax 
				url:"/step/#{window.step}/validated/"
				timeout:0
				success:(response)->
					if response.ok==true
						#also save the url fragment between redirections
						window.location.href = response.url+location.hash
	return {initialize:initialize}