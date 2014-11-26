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
	'text!services/placesService/templates/newContent.tmpl',
	'cs!modules/ApplicationManager',
	'cs!modules/ViewLoader'
]
,(tmpl,ApplicationManager,ViewLoader)->
	return class PostBoxView extends Backbone.Marionette.ItemView
		initialize:(options)->
			@template = _.template tmpl
			@current_view = null
		render:->
			ApplicationManager.get().then (instance)=>
				@$el.html @template({applications:instance.getApplications()})
				#select ansamb_post by default
				@applicationSelect('ansamb_post')
			@
		events:
			"click .application-list li":'applicationSelect'
		applicationSelect:(e)->
			@application_name = e
			ViewLoader.getView @application_name,'composer',(View)=>
				@current_view.close() if @current_view?
				@current_view = view = new View
				@$el.find('.composer').html view.render().$el
				view.on 'view:expand', =>
					@trigger 'view:expand'

		getApplicationContent: ->
			data = @current_view.getData()
			data.post = data.post.split('\n').join('<br/>') 
			app  = @application_name
			return {application :app, data : data}

		deleteApplicationData : ->
			@current_view.deleteData()



