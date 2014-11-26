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
path = require 'path'
# hound = require('hound')
env = require path.resolve('./settings/env.json')
async = require 'async'
_ = require 'underscore'
{EventEmitter} = require 'events'
# chokidar = require 'chokidar'
# rimraf = require 'rimraf'

module.exports = (options,imports,register)->
	api = new EventEmitter
	# _.extend api,
	# 	place_lib = imports['api.place']
	# 	place_content = imports['api.place.content']
	# 	account = imports['api.account']
	# 	Event = imports['events'].emitter
	# 	events = imports['events'].namespaced('file.watcher')
	# 	db = imports.database_manager
	# 	places_path = path.resolve options.file_dir, 'ansamb_file'
	# 	if process.platform == 'win32'
	# 		places_link_folder = path.resolve(process.env['USERPROFILE'], "Desktop/Places")
	# 	else 
	# 		places_link_folder = path.resolve(process.env['HOME'], "Desktop/Places")
	# 	places_table = new Array()
	# 	pooling_interval = 1000

	# 	# Create link to places on desktop
	# 	fs.symlink places_path, places_link_folder, 'dir', (exp) ->
	# 		console.log "link folder already exists" if exp?

	# 	# Register place to filesystem db
	# 	place_lib.on 'place:new', (place_return, folder_name)->
	# 		console.log 'place:new'
	# 		console.log folder_name
	# 		console.log place_return
	# 		db.getFilesystemDatabase (err, database)->
	# 			if err
	# 				console.log(err)
	# 				return
	# 			place_dir_path = path.resolve places_path, folder_name
	# 			mtime = fs.statSync(place_dir_path).mtime
	# 			database.models.global.place_dir.create({id:place_return.id, path: place_dir_path, mdate: mtime}).done (err, result) ->
	# 				if err then console.log(err) else console.log result

	# 	place_lib.on 'place:delete', (place_id)->
	# 		console.log 'place:delete'
	# 		db.getFilesystemDatabase (err, database)->
	# 			if err
	# 				console.log(err)
	# 				return
	# 			database.models.global.place_dir.find({'where':{'id': place_id}}).done (err, result) ->
	# 				if err
	# 					console.log(err)
	# 				else 
	# 					rimraf result.dataValues.path, (err)->
	# 						if err then console.log(err) else console.log("folder removed")
	# 					database.models.global.place_dir.delete({'id':place_id})
								

	# 	# Fetch all registered places
	# 	account.once 'account:checked', ()->
	# 		console.log 'account:checked'
	# 		place_lib.getAllPlace {type: 'share'}, {raw: true}, (err, places)->
	# 			_.each places, (place)->
	# 				places_table[place.name] = {id: place.id, files: new Array()}
	# 			resyncPlaces()

	# 	# Synchronize offline changes to places
	# 	resyncPlaces = () ->
	# 		db.getFilesystemDatabase (err, database)->
	# 			if err
	# 				console.log(err)
	# 				return
	# 			fs.readdir places_path, (err, place_dirs) ->
	# 				_.each place_dirs, (place_dir) ->
	# 					place_dir_path = path.resolve places_path, place_dir
	# 					stats = fs.statSync place_dir_path
	# 					if stats.isDirectory()
	# 						if not places_table[place_dir]?
	# 							console.log place_dir + " NOT SYNCED"
	# 							place_id = place_lib.createPlaceId('share',null,null).place_id
	# 							place_lib.addPlace {id: place_id, creation_date: new Date, type: 'share', name: place_dir, owner_uid: null} , {bd:{raw:true}}, (err, place)->
	# 								if err then console.log(err) else resyncDir(place_id, place.name, path.resolve(places_path, place.name))
	# 						database.models.global.place_dir.find({'where':{'path': place_dir_path}}).done (err, result) ->
	# 							if err
	# 								console.log(err) 
	# 							else 
	# 								if result?.dataValues?.mdate?
	# 									if (new Date(result.dataValues.mdate)).getTime() <= (new Date(stats.mtime)).getTime()
	# 										console.log place_dir + " UPDATED"
	# 										place_content._getContentsWithFilter result.dataValues.id, {content_type:'file'}, 2, (err, contents) ->
	# 											_.each contents, (content)->
	# 												places_table[place_dir].files[content.data.name] = {mdate: content.data.mdate, size: content.data.size}
	# 											resyncDir result.dataValues.id , place_dir, result.dataValues.path
	# 									else
	# 										console.log place_dir + " ALREADY SYNCED"

	# 	# Synchronize offline changes to folders/files
	# 	resyncDir = (place_id, place_name, dir_path) ->
	# 		fs.readdir dir_path, (err, files) ->
	# 			_.each files, (file) ->
	# 				file_path = path.resolve dir_path, file
	# 				stats = fs.statSync file_path
	# 				if stats.isDirectory()
	# 					resyncDir place_id, place_name, file_path
	# 				else
	# 					if not places_table[place_name]?.files[file]? 
	# 						console.log file + " NOT SYNC"
	# 						place_content._addContentToPlace place_id, {content_type: 'file'}, {name: file, size: stats.size, mdate:+new Date(stats.mtime)}, (err, bddObj)->
	# 							if err
	# 								console.log(err) 
	# 							else 
	# 								console.log('added to place')
	# 								db.getFilesystemDatabase (err, database)->
	# 									if err
	# 										console.log(err)
	# 										return
	# 									mdate = +new Date()
	# 									database.models.global.place_dir.update({mdate: mdate}, {id: place_id}).done (err, result) ->
	# 										if err then console.log(err) else console.log result

	# 	# Watch places folder
	# 	watcher = chokidar.watch places_path, {ignored: /[\/\\]\./, persistent: true, ignoreInitial: true, interval: pooling_interval}
	# 	watcher.on 'addDir', (dir_path) ->
	# 		if (dir_path.split(path.sep).length - places_path.split(path.sep).length) == 1
	# 			console.log "new place"
	# 			dir_name = path.basename dir_path
	# 			place_id = place_lib.createPlaceId('share',null,null).place_id
	# 			place_lib.addPlace {id: place_id, creation_date: new Date, type: 'share', name: dir_name, owner_uid: null} , {db:{raw:true}}, (err, place)->
	# 				if err then console.log(err) else resyncDir(place_id, dir_name, dir_path)
	# 	watcher.on 'add', (file_path, stats) ->
	# 		file_name = path.basename file_path
	# 		return if file_name == '.DS_Store'
	# 		place_name = path.dirname(file_path).replace(places_path, "").replace(path.sep, "")
	# 		place_lib.getPlaceFromName place_name, (err, bddObj)->
	# 			if err
	# 				console.log(err)
	# 			else
	# 				console.log bddObj
	# 				place_id = bddObj.id
	# 				place_content._addContentToPlace place_id, {content_type: 'file'}, {name: file_name, size: stats.size, mdate:+new Date(stats.mtime)}, (err, bddObj)->
	# 					if err
	# 						console.log(err)
	# 					else 
	# 						console.log('added to place') 
	# 						db.getFilesystemDatabase (err, database)->
	# 							if err
	# 								console.log(err)
	# 								return
	# 							database.models.global.place_dir.update({mdate:+new Date(stats.mtime)}, {id: place_id}).done (err, result) ->
	# 								if err then console.log(err) else console.log result
	# 	watcher.on 'change', (file, stats) ->
	# 		console.log file + ' was changed'
	# 		file_name = path.basename file
	# 		return if file_name == '.DS_Store'
	# 		place_name = path.dirname(file).replace(places_path, "").replace(path.sep, "")
	# 		place_lib.getPlaceFromName place_name, (err, bddObj)->
	# 			place_id = bddObj.id
	# 			events.emit "copying", place_id

	register null,{}