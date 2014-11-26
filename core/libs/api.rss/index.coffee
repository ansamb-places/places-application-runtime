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
RSS = require 'rss'
_ = require 'underscore'
uuid = require 'node-uuid'

module.exports = (options,imports,register)->
	global_options = options
	server = imports.server
	express = server.app
	place_api = imports["api.place"]
	content_api = imports["api.place.content"]
	api = 
		getFeedOptions:()->
			return options =
				title: "Places, RSS v0.1"
				description: "RSS about all places and contents"
				generator: "Places"
				feed_url: "http://localhost:8080/rss.xml"
				site_url: "http://joinplaces.com"
				managingEditor: "Places"
				copyright: "Places. All rights reserved. 2014"
				language: "en"
				categories: ["Cat1", "CatZ"]
				pubDate: new Date
				ttl: "60"
				#hub:

		generateItemforPlace:(place)->
			item =
				title: place.name
				description: "<strong>Detail:</strong><br/>"+"Description: "+place.desc+"<br/>Type: "+place.type+"<br/>LastSync: "+place.last_sync_date
				guid: place.id
				categories: ["Places"]
				author: place.owner
				date: place.creation_date
			return item

		generateItemforContent:(content)->
			item =
				title: content.data.name + " ("+ content.data.mime_type+")"
				description: "<strong>Detail:</strong><br/>"+"Type: "+content.content_type+"<br/>Last Update: "+content.updated_at
				guid: content.id
				categories: ["Places"]
				author: content.owner
				date: content.created_at
			return item

		generateRSSForAllPlace:(cb)->
			place_api.getAllPlace {},{}, cb

		generateRSSForPlace: (place_id, cb)->
			content_api.getContentForPlace place_id, 10 ,cb

	###
	%%%%%%%%%%%%%%%%%% http api definition %%%%%%%%%%%%%%%%%%%%%%%%
	###
	prefix = '/rss'
	express.get "#{prefix}",(req,res)->
		api.generateRSSForAllPlace (err, places)->
			if err?
				res.status(500).send('Something went wrong');
			else
				feed = new RSS api.getFeedOptions()
				_.each places, (place)->
					feed.item api.generateItemforPlace(place)
				res.set 'Content-Type':'application/xml'
				res.send feed.xml()

	express.get "#{prefix}/:place_id",(req,res)->
		if not req.param('place_id')
			res.status(400).send('Bad request')
			return
		api.generateRSSForPlace req.param('place_id'), (err, contents)->
			if err?
				res.status(500).send('Something went wrong');
			else
				feed = new RSS api.getFeedOptions()
				_.each contents, (content)->
					feed.item api.generateItemforContent(content)
				res.set 'Content-Type':'application/xml'
				res.send feed.xml()

	register null,{"api.rss":api}
