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
## This view display all Conversations in List
define [
	'cs!./MessageNotificationItemView'
],(Item)->
	class ConversationListView extends Backbone.Marionette.CollectionView
		itemView: Item
		initialize:->
			@nb_unread = 0
			@listenTo @collection,"sort",@render
			@listenTo @collection,"add",@incrementBadge
			@listenTo @collection,"last_content:changed",@updateBadge
			@listenTo @collection,"fetch",@updateBadge
		incrementBadge:(model)->
			if model.get("last_content")? and not model.get("last_content")?.read 
				@nb_unread++
				@renderBadge()
		decrementBadge:(model)->
			@nb_unread--
			@renderBadge()
		renderBadge:->
			badge= @$el.parent().prev().find(".message-notification")
			badge.html @nb_unread
			if @nb_unread>0
				badge.show()
			else badge.hide()
		updateBadge:()->
			@nb_unread= 0
			@collection.each (item)=>
				if item.get("last_content")?
					if not item.get("last_content").read
						++@nb_unread
			@renderBadge()
		onRender:->
			@updateBadge()			
			@$el.prev().find(".more").off('click')
			@$el.prev().find(".more").on 'click',=>
				@$el.parent().removeClass "open animated fadeInDown"
				@$el.parent().css("left", "-9999px")