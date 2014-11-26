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
	'cs!modules/localSettingsManager',
	"text!../templates/ng_home.tmpl",
	"cs!../../../node-webkit/links"
],(settingsManager,tmpl,links)->
	return class NGView extends Backbone.Marionette.ItemView
		className:'ng-home'
		template:(data) ->
			return _.template tmpl,data
		initialize:(options)->
			@loading= options.loading
			@contact_model=null
			@place_model=null
		serializeData:()->
			data={}
			data.contact=null
			data.place=null
			data.loading= @loading
			data.contact_imported = settingsManager.getSetting('contact_imported')
			data.ng_invite= if settingsManager.getSetting('ng_invite')== "done" then true else false
			if !data.loading
				if @contact_model
					data.contact=@contact_model.attributes
				if @place_model
					data.place=@place_model.attributes
			return data
		onRender:->
			links.openInBrowser @$el.find('#link_twitter')
		ui: null
		events: 
			"click .p-ng-place-accept":"place_accept"
			"click .p-ng-contact-accept":"contact_accept"
			"click .p-ng-ok-accept":"send_accept"
			"click .p-background-grey":"cancel"
		place_accept:(e)->
			e.stopPropagation()
			console.log "place accept"
			@trigger "place:accept"

		contact_accept:(e)->
			e.stopPropagation()
			console.log "contact accept"
			@trigger "contact:accept"

		send_accept:(e)->
			e.stopPropagation()
			console.log "send accept"
			@trigger "send:request"
		cancel:(e)->
			e.stopPropagation()
			console.log "cancel"
			@trigger "cancel"
		
		showLoading:(bool)->
			@loading=bool
			@render()
