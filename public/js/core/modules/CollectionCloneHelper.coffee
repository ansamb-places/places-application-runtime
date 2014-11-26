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
define [],()->
	class CollectionCloneHelper
		clone:(originalCollection)->
			clonedCollection = originalCollection.clone()
			#all events on original collection are replicated on cloned collection
			events=
				'add':(model)->
					clonedCollection.add(model)
				###'change':(model)->
					clonedCollection.get(model).set(model)###
				'remove':(model)->
					clonedCollection.remove model
			_.each events,(item,index)->
				originalCollection.on index,item
			clonedCollection.unbind=()->
				#delete events
				_.each events,(item,index)->
					originalCollection.off index,item
			return clonedCollection
	return new CollectionCloneHelper