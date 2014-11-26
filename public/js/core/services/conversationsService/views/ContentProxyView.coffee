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
define ['text!../templates/ContentProxy.tmpl','moment'],(tmpl,Moment)->
	return class ContentProxy extends Backbone.Marionette.ItemView
		tagName:"li"
		template:(json)->
			return _.template tmpl,json
		serializeData:->
			json = @model.toJSON()
			json.date= Moment.utc(json.date).local().format("ddd MM/DD/YY HH:mm")
			json.color = @options.color
			if json.owner == null
				json.fullname = "Me"
			else
				if json.owner_extra?
					json.fullname = json.owner_extra?.firstname+" "
					if json.owner_extra?.lastname?.length
						json.fullname += json.owner_extra.lastname[0].toUpperCase()
			return json
		concreteViewContainer:'.concrete'
		initialize:(options)->
			@$concreteViewEl = null
			@concreteView = null
			@options = options
		onRender:->
			if @options?.content_view_promise
				@options.content_view_promise.done (View)=>
					@concreteView = new View _.omit(@options,'content_view_promise')
					@concreteView.render()
					@$el.find(@concreteViewContainer).html @concreteView.$el
					# Event proxy (from concrete to proxy view)
					originalTrigger = @concreteView.trigger
					@concreteView.trigger = ()=>
						originalTrigger.apply @concreteView, arguments
						@trigger.apply @, arguments
		onClose:->
			if @concreteView?
				@concreteView.close() if @concreteView?.close?