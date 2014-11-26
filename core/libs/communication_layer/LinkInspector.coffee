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
http = require 'http'
querystring = require 'querystring'
uuid = require 'node-uuid'
BSON = require('bson').native()
bson = new BSON.BSON([BSON.Code,BSON.Long,BSON.ObjectID,BSON.Binary,BSON.DBRef,BSON.Symbol,BSON.Double,BSON.Timestamp,BSON.MinKey,BSON.MaxKey])

link_inspector_sess = uuid.v4()
link_inspector_ip = 'linkinspector.dev.places.lan'
link_boot_time = +new Date
module.exports = (direction, uid, sessid, data)->
	owner = process.env.LINK_INSPECTOR_OWNER || 'rudylacrete'
	if direction=='out'
		data.dst = data.dst||'local'
		data.src = uid
	else
		data.dst = uid
		data.src = data.src||'local'
	data = bson.serialize(data,false,true,false)
	ts = ((+new Date)-link_boot_time)/1000
	path = "/api.php?owner=#{owner}&me=#{uid}&sess=#{sessid||link_inspector_sess}&type=packet&ts=#{ts}"
	req = http.request {
		host:link_inspector_ip
		port:80
		method:'POST'
		path:path
	},(response)->
		data = ''
		response.setEncoding 'utf8'
		response.on 'data',(chunk)->
			data += chunk
		response.on 'end',->
			# console.log "response:",data
	req.write data
	req.on 'error',(error)->
		# console.error error
	req.end()