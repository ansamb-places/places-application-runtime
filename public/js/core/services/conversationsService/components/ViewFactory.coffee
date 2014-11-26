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
	'cs!../views/ChatBoxConversationView',
	'cs!../views/HidenConversationView',
	'cs!../views/ConversationsListView',
	'cs!../views/MessageNotificationView',
	'cs!../entities/Conversations',
	'cs!common/views/DialogBoxView'
],(ChatBoxConversation,HidenConversationView,ConversationsListView,MessageNotificationView,Conversations,DialogBoxView)->
	return {
		buildChatBoxConversation:(place_id,ansambers,mode)->
			place = Conversations.findWhere(id:place_id)
			return new ChatBoxConversation {place:place,ansambers:ansambers,mode:mode}
		# buildFullScreenConversation:->
		# 	return new FullScreenConversation
		buildStackChat:()->
			return new HidenConversationView
		buildConversationsList:(options)->
			options = options ? {}
			options = _.extend options,{collection:Conversations}
			return new ConversationsListView options
		buildConversationsNotificationView:(options)->
			options = options ? {}
			options = _.extend options,{collection:Conversations}
			return new MessageNotificationView options
		buildDialogBox:(message, actions, options)->
			return new DialogBoxView {message:message, actions:actions, options:options}
	}