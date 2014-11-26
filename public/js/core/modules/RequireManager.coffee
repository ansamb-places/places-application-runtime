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
define [],->
	_contextStore = {}

	#we expose the sandbox require getter to inject it into the 'ansamb_context' module
	return window._require = (app_name)->
		return _contextStore[app_name]||(()->
			_contextStore[app_name] = require.config
				context:app_name
				baseUrl:'/application/static/'+app_name+'/public'
				paths:
					'ansamb_context':'/js/core/modules/ContextModule'
					'urlHelper':'/js/core/modules/UrlHelper'
				config:
					'ansamb_context':
						appName:app_name
				waitSeconds:10
			#inject some generic modules into the new require's context
			toInject = ["text","cs","_css","coffee-script","socket.io","moment","tiptip"]
			_.each toInject,(mod)->
				# _ is the global context which is used when no context is defined
				require.s.contexts[app_name].defined[mod] = require.s.contexts._.defined[mod]
			return _contextStore[app_name];
		)()