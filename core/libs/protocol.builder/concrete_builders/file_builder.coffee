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
#this protocol is used to manage file download by the kernel
_ = require 'underscore'
kernel_common = 
	ver:1
	protocol:'fs'
	dst:'local'
module.exports = 
	name:'file'
	api:
		downloadRequest:(data)->
			_.extend
				method:'DOWNLOAD'
				content_id:data.content_id
				spl:data.place
				dpl:data.place
				data:
					ansamb_extras:data.ansamb_extras
				args:data.args
			,kernel_common
		getStatus:(data)->
			_.extend
				method:'STATUS'
				spl:data.place
				dpl:data.place
				content_id:data.content_id
			,kernel_common