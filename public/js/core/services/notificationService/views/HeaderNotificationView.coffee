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
	'cs!./NotificationItemView'
	'cs!./NotificationEmptyView'
	'cs!backend_api/NotificationBackendAPI'
],(ItemView,EmptyView,notificationAPI)->
	return class HeaderNotificationView extends Backbone.Marionette.CollectionView
		emptyView:EmptyView
		initialize:(options)->
			super options
			@listenTo @collection,'add',@updateBadge
			@listenTo @collection,'change',@updateBadge
			@listenTo @collection,'remove',@updateBadge
			@listenTo @,'itemview:item:click',@itemClicked
		getItemView:->
			return ItemView
		itemClicked:->
			@$el.foundation('dropdown','close',@$el)
		appendHtml:(collectionView, itemView, index)->
			if collectionView.isBuffering
				collectionView.elBuffer.insertBefore(itemView.el,collectionView.elBuffer.firstChild)
			else
				collectionView.$el.prepend(itemView.el)
		getBadgeEl:->
			return @$el.parent().parent().find('.message-notification')
		setBadgeValue:(value)->
			badge = @getBadgeEl() 
			return if not _.isNumber value
			badge.html value
			if value==0
				badge.hide()
			else badge.show()
		updateBadge:->
			@setBadgeValue @collection.where({read:false}).length
		getBadgeValue:->
			return +@getBadgeEl().html()
		# emptyView: EmptyView
		onRender:->
			@updateBadge()
			@$el.prev().find(".read_all").off('click')
			@$el.prev().find(".read_all").on 'click',=>
				notificationAPI.markAsRead().done =>
					@collection.each (model)->model.markRead()
				@$el.parent().removeClass "open animated fadeInDown"
				@$el.parent().css("left", "-9999px")