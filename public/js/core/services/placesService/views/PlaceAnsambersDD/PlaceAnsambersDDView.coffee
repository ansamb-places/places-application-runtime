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
	"cs!./PlaceAnsambersDDItemView"
	"text!../../templates/PlaceAnsambersDD.tmpl"
	"cs!modules/ContactSearchModule"
	"cs!common/views/SortedCompositeView"
	],(ItemView,template,ContactSearch,SortedCompositeView)->
	class PlaceAnsambersDDView extends SortedCompositeView
		#This is the dropdown view which is used to add ansamber to a place
		#
		tagName: 'div'
		className: 'p-ansambers-dropdown-menu'
		itemView: ItemView
		$toolbarMenuEl: null
		$countTag:null
		initialize:(options)->
			super(options)
			@listenTo @collection,'change',()->
				@collection.sort()
			@listenTo @collection,'remove',@itemRemoved
			@place_id= options.place_id || "default"
			@placeOwner= options.placeOwner || null
		ui:{}
		template:()=>
			return _.template template,{placeOwner:@placeOwner}
		itemViewContainer: 'ul'
		itemViewOptions:(model, index)->
			return{placeOwner:@placeOwner}
		onRender:()->
			if !@placeOwner
				ContactSearch @$el.find("#p-member-dropdown-searchinput"),@place_id,@$el.find('.p-add-ansamber'),()=>
					#to close dropdown on click on add button
					@ui.dropdown_a.click()
			@$countTag= @$toolbarMenuEl.find('.ansambers_count')
			@update_count()
			$(document).foundation('reflow','dropdown')
			@ui.dropdown = @$el.parent()
			@ui.dropdown_a= @ui.dropdown.parent().find("[data-dropdown="+@ui.dropdown.attr('id')+"]")
		update_count:()->
			@$countTag.html(@collection.length) if @$countTag
		onAfterItemAdded:()->
			@update_count()
		itemRemoved:->
			@update_count()
		onItemRemoved:->
			@update_count()
