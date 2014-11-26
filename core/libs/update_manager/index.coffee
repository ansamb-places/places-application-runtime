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
path = require 'path'
spawn = require('child_process').spawn
env = require path.resolve('./settings/env.json')

module.exports = (options,imports,register)->
	# plugin dependencies
	server = imports.server
	express = server.app
	events = imports['events'].namespaced('update_manager')
	notification_manager = imports["notification_manager"]
	account = imports['api.account']
	
	# plugin vars
	florebo_main_dir = env.florebo_main_dir || "../../ansamb_florebo-main/bin"
	florebo_secondary_dir = env.florebo_secondary_dir || "../../ansamb_florebo-secondary/bin"
	florebo_main_path = path.resolve florebo_main_dir, 'florebo.sh'
	florebo_secondary_path = path.resolve florebo_secondary_dir, 'florebo.sh'

	# start florebo_process once user checked
	account.once 'account:checked', ()->
		setTimeout ->
			console.log "FLOREBO LAUNCH"
			florebo_main_process = spawn florebo_main_path, ['check_update','=u','http://localhost:8080/core/api/update_manager/']
			# handle florebo streams and closing
			florebo_main_process.stdout.on 'data', (data) ->
				console.log 'florebo_main stdout: ' + data
			florebo_main_process.stderr.on 'data', (data) ->
				console.log 'florebo_main stderr: ' + data
			florebo_main_process.on 'close', (code) ->
				console.log 'florebo_main exited with code: ' + code
			florebo_main_process.on 'error',(err)->
				console.log err
			florebo_secondary_process = spawn florebo_secondary_path, ['check_update','=a']
			# handle florebo streams and closing
			florebo_secondary_process.stdout.on 'data', (data) ->
				console.log 'florebo_secondary stdout: ' + data
			florebo_secondary_process.stderr.on 'data', (data) ->
				console.log 'florebo_secondary stderr: ' + data
			florebo_secondary_process.on 'close', (code) ->
				console.log 'florebo_secondary exited with code: ' + code
			florebo_secondary_process.on 'error',(err)->
				console.log err
		, 20000

	###
	%%%%%%%%%%%%%%%%%% http api definition %%%%%%%%%%%%%%%%%%%%%%%%
	###
	prefix = server.url_prefix.core_api+'/update_manager'
	florebo_res = null
	already_asked = false
	already_done = false
	express.post "#{prefix}/",(req,res)->
		console.log "FLOREBO REQUEST"
		res.send({code: 400}) if not req.body?.content_type?
		switch req.body.content_type
			when 'new_updates'
				if (already_asked == true) || (not req.body.data?)
					res.send({code: 400})
				else
					already_asked = true
					florebo_res = res
					notification_manager.createNotification null,null,{timestamp: (new Date()).getTime()},'update:available','*',true,false
			when 'update_done'
				if already_done == false
					notification_manager.createNotification null,null,{},'update:done','*',true,false
					res.send {code: 200}
			else res.send {code: 400}

	express.post "#{prefix}/user_answer",(req,res)->
		if (florebo_res != null) and (req.body?.answer?)
			if req.body.answer is 'accept' then florebo_res.send({code: 200}) else florebo_res.send({code: 400})
			res.send({code :200})
		else
			res.send({code: 400})

	register null,{}