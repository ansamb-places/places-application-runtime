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
	'hello',
	'cs!modules/localSettingsManager',
	'text!../templates/importContacts.tmpl',
	'text!../templates/importedContactSuggest.tmpl'
],(hello,settingsManager,tmpl,suggest_tmpl)->
	class ImportContactsView extends Backbone.Marionette.ItemView
		className: 'p-contact-import'
		initialize:(options)->
			settingsManager.setSetting('contact_imported',"true")
			_.extend @,Backbone.Events
			hello.init { 
				#google :
			},{
				scope:'friends'
				redirect_uri:'/redirect/'}
			@step=0
			@steps=[null,@selectNetwork,@inviteContacts]
			super(options)
		
		template:-> tmpl
		ui:
			request:".p-import-requests"
		events:
			'click .p-next':'nextStep'
			'click .p-leave':'leave'

		onClose:()->
			hello.logout(null,{force:true})
		getImportedContacts:(network)->
			hello(network,{scope:'friends'}).login().then ()=>
				hello( network ).api( "me/contacts" , {},(r)=>
					emails= _.chain(r.data)
						.map (item)->
							item.email
						.filter (email)->
							return email and email!=""
						.unique()
					@emails= emails._wrapped
					#@displayImportedContact @emails
					@nextStep()
					hello.logout({force:true})
				)
			,(e)->
				console.log("Signin error: " + e.error.message );

		displayImportedContact:(contacts)->
			@template= -> JSON.stringify(contacts) + '<input class="p-button-round p-background-grey p-button-padding p-next" type="button" value="next"/>'
			@render()

		nextStep:(e)->
			@step++ if @steps[@step+1]()

		selectNetwork:()=>
			#@network= @$el.find("input:radio[name=network]:checked").val()
			@network='google' #only google is supported
			return if !@network
			@ui.request.html(
				"<span class='bold'>waiting for you to connect on #{@network} platform </span><br/>
				<span data-icon='l' class='p-loading p-color-contact p-big'></span><br/>
				<span class='p-next p-button-round p-background-grey p-button-padding p-ng-contact-accept'>leave</span>")
			@getImportedContacts(@network)
			return true

		inviteContacts:()=>
			@trigger 'search:contacts',@emails
			return
			$loading= $(
				"<span data-icon='l' class='p-loading p-color-contact p-big'></span><br/>"
			)
			@$el.html($loading)
			promises=[]
			_.each @emails,(email)=> 
				promises.push ContactBackendAPI.searchContact(email).done (contact)=>
					contact.email= email if contact
					@showContact(contact)
			$.when.apply(@,promises).done ()->
				$loading.remove()
			.fail ()->
				$loading.html("fail to Launch some contacts")
		leave:()->
			@trigger 'action:leave'
	return ImportContactsView