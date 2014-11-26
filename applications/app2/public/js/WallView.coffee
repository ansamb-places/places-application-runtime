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
	'ansamb_context',
	'_css!css/style.css',
	'text!views/application.html',
	'cs!js/CustomModel'
	],(c,css,text,CustomModel)->
	class WallView extends Backbone.View
		initialize:(options)->
			@original_model = @model
			@placeName = options.placeName||"default"
			c.socketio.on "#{@placeName}:message",(data)->
					alert JSON.stringify(data)
		render:=>
			@$el.empty()
			@$el.html "Loading ..."
			#get application content
			$.get "/application/#{c.appName}/content/#{@original_model.get('id')}?place_name=#{@placeName}",(response)=>
				@model = new CustomModel(response.data)
				@$el.html "content #{@original_model.get('id')} loaded"
			@
		events:
			'click':'onClick'
		onClick:->
			c._require ['cs!js/DetailView'],(View)=>
				c.mainApplication.popupRegion.show(new View({model:@model}))
	return WallView