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
define ['ansamb_context',
		'cs!modules/ViewManager',
		'text!/../templates/mainView.html',
		'cs!collections/ContentCollection'
		]
,(c,ViewManager,template,Collection)->
	_viewManager = new ViewManager
	contents = new Collection
	class MainView extends Backbone.View
		initialize:->
			@listenTo @collection,'add',@addContent
			@$app_el = $("#application-container")
		render:->
			@$el.html template
			contents.fetch()
			@
		addContent:(model)->
			_viewManager.getView "app3:wall",(View)=>
				v = new View({placeName:'default',model:model})
				@$app_el.append v.render().$el
		events:
			"click .btn":"btnClick"
		btnClick:(b)->
			app = $(b.currentTarget).data("app")
			_viewManager.getView "#{app}:wall",(View)->
				v = new View({placeName:'default2'})
				$("#application-container").append(v.render().$el)
	v = new MainView({collection:contents})
	c.socketio.on 'new_content',(data)->
		contents.add data
	return v