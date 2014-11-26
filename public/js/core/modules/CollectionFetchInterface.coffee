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
	return{
		ensureFetchPromise:()->
			@interface_fetched= $.Deferred() if not @interface_fetched 
		fetch:()->
			@_p_fetched = false
			@ensureFetchPromise()
			args= Array::slice.call(arguments)
			if args.length == 0 or (args.length>1 and typeof args[0] != 'object')
				args[0]={}
			args[0].success= ()=>
				@_p_fetched = true
				@interface_fetched.resolve.apply null,arguments
			args[0].error= ()=>
				@interface_fetched.reject.apply null,arguments
			args[0].remove= false
			Backbone.Collection::fetch.apply(@,args)
		onAfterFetch:(cb)->
			@ensureFetchPromise()
			@interface_fetched.done cb
		isFetched:->
			return @_p_fetched ? false
	}