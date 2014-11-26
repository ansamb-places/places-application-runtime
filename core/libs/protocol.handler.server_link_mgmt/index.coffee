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
protocol_name = 'link_mgmt'

module.exports = (options,imports,register)->
	link_mgnt = imports["server_link_management"]

	protocolHandler = (message)->
		switch message.method
			when "STATUS_CHANGE"
				link_mgnt.setStatus message?.data?.status,{notify_ui:true}
			else
				console.error "Method #{message.method} of protocol #{protocol_name} is not supported"

	imports["protocol.handler"].registerProtocolHandler protocol_name,protocolHandler
	register null,{}