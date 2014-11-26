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
	'text!../templates/hidenConversationItem.tmpl',
],(template)->
	return class View extends Backbone.Marionette.ItemView
		template: _.template template
		tagName: 'li'
		className: 'p-stacked-chat'
		events:
			"click":"actionTrigger"
		serializeData:()->
			data= {}
			if @model
				data = @model.toJSON()
				ansambers = ""
				_.each @model.get("ansambers"),(item,key)->
					if key!=0 and key < data.ansambers.length
						ansambers= ansambers+" , "
					lastname_letter= item.lastname[0] || ""
					ansambers= ansambers+item.firstname+" "+lastname_letter+"."
				data.ansambers= ansambers
			return data
		actionTrigger:(e)->
			e.preventDefault()
			action= "select"
			@trigger "chatbox:#{action}",@model