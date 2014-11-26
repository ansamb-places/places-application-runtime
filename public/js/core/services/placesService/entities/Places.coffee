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
	class Place extends Backbone.Model
		defaults:
			name:""
			selected:false
			unreadCount:0
		incrementBadge:->
			@set 'unreadCount',@get('unreadCount')+1
		decrementBadge:->
			@set 'unreadCount',@get('unreadCount')-1
		setBadge:(number)->
			@set 'unreadCount',number
		isSyncable:->
			return not @isDisabled() and @isReady()
		isDisabled:->
			return @get('status') == "disabled"
		isReady:->
			return @get('network_synced') == 2
		isReadOnly:->
			if @get('status') == 'readonly'
				if @get('owner')== null
					return false
				return true
			return false
	class Places extends Backbone.Collection
		model:Place
		comparator:(model)->
			model.get("name").toLowerCase()
		initialize:(models, options)->
			super models, options
			@url = options.url if options?
		parse:(response,options)->
			return response.data||[]
	return {model:Place,collection:Places}