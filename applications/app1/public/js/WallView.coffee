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
class WallView extends Backbone.View
	initialize:->
	render:=>
		@$el.empty()
		@$el.html $("#fragment").html()
		@
	events:
		'click #link':'clickHandler'
	clickHandler:->
		$.get '/app1/hello',(data)->
			alert JSON.stringify(data)
		window._viewManager.getView "app1:application",(View)=>
			v = new View()
			@$el.html v.render().$el

window._viewManager.registerView("app1:wall",WallView)