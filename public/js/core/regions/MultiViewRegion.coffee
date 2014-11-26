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
define [],()->
	Backbone.Marionette.Region.MultiView = Backbone.Marionette.Region.extend
		viewArray:{}
		show:(view,key)->
			@ensureEl()
			view.render()
			Backbone.Marionette.triggerMethod.call(@,"show",view)
			Backbone.Marionette.triggerMethod.call(view,"show")
			@open(view,key)
		open:(view,key)->
			@$el.append(view.el)
			@viewArray[key] = view
		close: ->
			for i,v of @viewArray
				v.remove()
			@viewArray = {}
			Marionette.triggerMethod.call this, "close"
		onShow:(view)->		
			return
		empty:(key)->
			if @viewArray.hasOwnProperty(key)
				@viewArray[key].$el.remove()
				delete @viewArray[key]
	return Backbone.Marionette.Region.MultiView