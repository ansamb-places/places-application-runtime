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
define [],->
	class SortedCompositeView extends Backbone.Marionette.CompositeView
		initialize:(options)->
			super(options)
			@listenTo @collection, 'sort', @_sortViews
		_sortViews:()->
			# check for any changes in sort order of views
			orderChanged = this.collection.find (item, index)->
				view = this.children.findByModel(item)
				return view && view._index != index
			,@
			if orderChanged
				@render()
		_insertBefore: (childView, index)->
			currentView;
			findPosition = this.sort && (index < this.children.length - 1)
			if (findPosition) 
				#Find the view after this one
				currentView = this.children.find (view)->
					return view._index == index + 1
			if currentView
				currentView.$el.before(childView.el)
				return true;
			return false;
		_updateIndices: (view, increment, index)->
			if (!this.sort) 
				return;
			if (increment)
				view._index = index;
				@children.each (laterView)->
					if (laterView._index >= view._index)
						laterView._index++;
			else 
				this.children.each (laterView)->
					if (laterView._index >= view._index)
						laterView._index--;
		attachHtml: (collectionView, childView, index)->
			if (collectionView.isBuffering) 
				collectionView.elBuffer.appendChild(childView.el);
				collectionView._bufferedChildren.push(childView);
			else 
				if (!collectionView._insertBefore(childView, index))
					collectionView._insertAfter(childView);
		addChild:(child, ChildView, index)->
			childViewOptions = this.getOption('childViewOptions');
			if (_.isFunction(childViewOptions))
				childViewOptions = childViewOptions.call(this, child, index);
			view = this.buildChildView(child, ChildView, childViewOptions);
			this._updateIndices(view, true, index);
			this._addChildView(view, index);
			return view;
		removeChildView:(view)->
			if (view)
				this.triggerMethod('before:remove:child', view);
				if view.destroy 
					view.destroy()
				else if view.remove
					view.remove()
				this.stopListening(view);
				this.children.remove(view);
				this.triggerMethod('remove:child', view);
				this._updateIndices(view, false);