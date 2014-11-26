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
define [
	'cs!app'
	'cs!./ShortcutsViews'
	],(App,View)->
		##array wich store the inpu action type, the shortkey , the description of the action, and the action to do
		_events=[
			{action:'keydown',shortkey:"ctrl+F", desc:'Focus on the SearchBar',do:()->
				$("#p-search-input").focus()
				},
			{action:'keydown',shortkey:"ctrl+H",desc:'Display Help', do:()->
				App.popupRegion.show new View {collection: _events}
			}
		]
		#binding all event to the dom
		_.each _events,(item,index)->
			$(document).bind(item.action,item.shortkey,item.do)