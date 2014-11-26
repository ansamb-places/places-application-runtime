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
express = require 'express'
flash = require('express-flash')
path = require 'path'
StepManager = require './StepManager'
ansamb_middlewares = require '../../common_lib/express_middlewares'
fs = require 'fs'
stepManager= new StepManager
_when = require 'when'

i18n = require 'i18next'

express_app = express()

i18n_loaded = _when.defer()
i18n.init {
	saveMissing: false,
	seCookie: false,
	lng: 'en_US'
},
(t) ->
	express_app.locals.t = t
	i18n_loaded.resolve()

express_app.configure ->
express_app.use(express.json())
express_app.use(express.urlencoded())
express_app.use(ansamb_middlewares.xss_sanitizer())
express_app.use(express.methodOverride())
express_app.use(express.cookieParser("745QZIuGK2QyTJuCWg/Wag=="))
express_app.use(express.session({
  secret: 'd19e19fd62f62a216ecf7d7b1de434ad',
  cookie: { maxAge: 60000 }
}))

#express_app.use(i18n.handle);

express_app.use(flash())

express_app.set('views', process.cwd() + '/views')
express_app.use(express["static"](process.cwd() + '/public'))
express_app.set('view engine', 'jade')
express_app.use(express.errorHandler({
	dumpExceptons: true,
	showStack: true
}))
express_app.use(stepManager.routeFiltering())
express_app.use(express_app.router)

server = require('http').createServer(express_app)
# this flag tells if the framework is ready or not
is_ready = false

i18n.registerAppHelper(express_app);

if process._argv.filtering == false
	console.log "disable http filtering ....."
	stepManager.disableFiltering()

static_middleware = (url,dir_path)->
	(req,res)->
		file_path = path.join(dir_path,req.originalUrl.substr(req.originalUrl.indexOf(url)+url.length))
		file_path = file_path.substr(0,file_path.indexOf('?')) if file_path.indexOf('?')!=-1
		res.sendfile(file_path)

module.exports = (options,imports,register)->
	port = options.port||8080
	if process._argv.listenAll == true
		server.listen port
	else
		server.listen port,"127.0.0.1"
	i18n_loaded.promise.done ->
		register null,
			server:
				app:express_app
				http:server
				static_middleware:static_middleware
				stepManager:stepManager
				i18n: i18n
				url_prefix:
					app_api:'/application/api/v1'
					core_api:'/core/api/v1'
					core_assets:'/core/assets'
				is_ready:->
					return is_ready
				set_is_ready:(ready)->
					is_ready = !!ready
