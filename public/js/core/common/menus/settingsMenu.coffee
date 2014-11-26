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
define [''],->
	return (options)->
		obj = {
			title: "<span class='p-setting-toolbar-title'>"+(options?.title || "account")+"</span>"
			menu:[
				##{name : "profile", href : "#account/profile",item_id:"item/profile"},
				##{name : "contacts", href : "#contact/manage",item_id:"item/contacts"},
				##{name : "conversations", href : "#conversation/history",item_id:"item/conversations"}
				##{name : "list of places", href : "#settings/place",item_id:"item/places"}
			]
			id: "menu/"+(options?.title || "settings")
		}
		obj.menu = options.menu if options.menu
		return obj
