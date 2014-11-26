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
fs = require('fs')

module.exports = 
	init:(router)->
		router.on('get','/',api.handleRootRequest)
		router.on('get','/:test',api.test)
		router.on('get','/getview/:type',viewManager.handleRequest)
		router.on('get','/public/*',api.serveFile('/public/'))

api = 
	handleRootRequest:(req,res)->
		# res.send("c'est coool "+req._context.dbname+", "+res.locals.app)
		# res.render("p #{app} #{cool}\na(href=\"#{PathTo('/hello')}\") test link",{cool:"coolllll"})
		t = viewManager.getView('index')
		res.render(t.view,t.params)
	test:(req,res)->
		res.send({ok:req.param("test")})
	serveFile:(rootUrl)->
			(req,res)->
				publicDir = __dirname+"/public/"
				url = publicDir+req.originalUrl.substr(req.originalUrl.indexOf(rootUrl)+rootUrl.length)
				url = url.substr(0,url.indexOf('?')) if url.indexOf('?')!=-1
				res.sendfile(url)
class ViewManager
	handleRequest:(req,res)=>
		t = this.getView(req.param('type'))
		res.render(t.view,t.params)
	getView:(type)->
		template = {}
		template['wall'] = {
			view:fs.readFileSync(__dirname+'/views/wall.jade'),
			params:{param:"toto"}
		}
		template['application'] = {
			view:fs.readFileSync(__dirname+'/views/index.jade'),
			params:{}
		}
		return template[type]

viewManager = new ViewManager