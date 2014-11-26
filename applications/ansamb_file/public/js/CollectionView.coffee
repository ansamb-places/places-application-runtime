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
	'text!template/collection.tmpl',
	'cs!js/ViewGetter'
	],(c,tmpl,vg)->
	class CollectionView extends Backbone.Marionette.CompositeView
		template:()->
			return tmpl
		tagName: 'div'
		itemViewContainer: 'ul'
		getItemView:(item)->
			return vg(item.get('data').name)
		initialize:(options)->
			@place_id=options.place_id
			@collection = options.collection
		itemViewOptions:(model, index)->
			if index>4
				#only 5 first item collection are displayed by default
				return {model:model,place_id:@place_id,isCollection:true,tagName:'li',hide:true,type:'wall'}
			else
				return {model:model,place_id:@place_id,isCollection:true,tagName:'li',hide:false,type:'wall'}
		events:
			"click .more": "displayAll"
		onRender:->
			if @collection.length <5
				@$el.find('.more').addClass('hide')
			if @collection.length == 0
				@$itemViewContainer.html "The collection is empty"
		displayAll:(e)->
			e.preventDefault()
			@$itemViewContainer.children().removeClass('hide')
			@$el.find('.more').remove()