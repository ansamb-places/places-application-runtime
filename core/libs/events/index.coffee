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
EventEmitter = require('eventemitter2').EventEmitter2
utils = require '../../common_lib/utils'
module.exports = (options,imports,register)->
	emitter = new EventEmitter
	namespaced = (namespace)->
		namespaced_emitter = utils.methodObj(emitter)
		#override emit function to namespace the event
		namespaced_emitter.emit = ->
			args = Array::slice.call(arguments)
			args[0] = "#{namespace}:#{args[0]}"
			console.log "[EVENT] #{args[0]}:",args.slice(1)
			emitter.emit.apply(emitter,args)
		return namespaced_emitter
	register null,{events:{emitter:emitter,namespaced:namespaced}}