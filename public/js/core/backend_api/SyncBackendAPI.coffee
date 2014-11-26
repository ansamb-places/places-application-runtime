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
define ->
	sync=
		enable:'enable'
		disable:'disable'
	return {
		enableSyncForPlace:(place_id,options)->
			done = $.Deferred()
			query_options = {}
			if typeof options?.reset == 'boolean'
				query_options.reset = options.reset
			$.get "/core/api/v1/sync/#{place_id}/#{sync.enable}",query_options,(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.ok)
			.fail ->
				done.reject "Request error"
			return done.promise()
		disableSyncForPlace:(place_id)->
			done = $.Deferred()
			$.get "/core/api/v1/sync/#{place_id}/#{sync.disable}",(reply)=>
				if reply.err?
					done.reject reply.err 
				else
					done.resolve(reply.ok)
			.fail ->
				done.reject "Request error"
			return done.promise()
		enableAutoSyncForPlace:(place_id)->
			done = $.Deferred()
			$.get "/core/api/v1/sync/auto/#{place_id}/enable",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve()
			.fail ->
				done.reject "Request error"
			return done.promise()
		disableAutoSyncForPlace:(place_id)->
			done = $.Deferred()
			$.get "/core/api/v1/sync/auto/#{place_id}/disable",(reply)=>
				if reply.err?
					done.reject(reply.err)
				else
					done.resolve(reply.last_sync_date)
			.fail ->
				done.reject "Request error"
			return done.promise()
	}