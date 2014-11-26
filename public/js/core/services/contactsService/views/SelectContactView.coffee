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
define ['text!../templates/SelectContact.tmpl','cs!./SelectContactItemView'],(tmpl,ItemView)->
	return class SelectContactView extends Backbone.Marionette.CompositeView
		itemView:ItemView
		itemViewContainer:'.container'
		template:->
			return tmpl
		events:
			'click .p-button-round':'confirm'
		confirm:(e)->
			models = @collection.where selected:true
			@trigger 'selectedContacts',_.map models,(item)->item.toJSON()
			@close()
		#allow to define which contacts have to be disabled and already checked
		setDisabledElements:(uids)->
			return if _.isUndefined uids or uids==null
			uids = [uids] if not _.isArray(uids)
			for uid in uids
				model = @collection.findWhere({uid:uid})
				model.set 'disabled',true if model?