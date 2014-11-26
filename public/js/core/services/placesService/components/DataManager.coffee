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
### DataManager
In charge fetch entities collections
return collection when a components ask it
###
define [
	'cs!services/placesService/entities/Places',
	'cs!services/placesService/entities/Ansambers',
	"cs!entities/Contents",
	'backbone-filtered-collection',
	'cs!modules/CollectionCloneHelper'
],(PlacesEntities,AnsambersEntities,ContentEntities,FilteredCollection,CloneHelper)->
	class DataManager
		places: new PlacesEntities.collection null, {url:"/core/api/v1/places/?type=share"}
		ContentsCollectionCache:null
		constructor:()->
			@places.fetch()
		getFilteredPlacesCollection:(filter)->
			filteredPlaces = new FilteredCollection @places
			if filter?
				filteredPlaces.filterBy('filter',filter)
			return filteredPlaces
		getPlaceCollection:()->
			return @places
		addPlace:(place)->
			@places.add new PlacesEntities.model place
		deletePlace:(place_id)->
			@places.remove({id:place_id})
		getAnsambers:(place_id,options)->
			options= {} if not options 
			options.url= "/core/api/v1/places/#{place_id}/ansambers/"
			collection= new AnsambersEntities.collection null, options
			collection.fetch()
			return collection
		getAnsambersUidArray:(place_id)->
			done= $.Deferred()
			collection= new AnsambersEntities.collection null, {url:"/core/api/v1/places/#{place_id}/ansambers/"}
			collection.fetch().done ()->
				done.resolve(_.map(collection.toJSON(),(item)-> return item.uid))
			return done.promise()
		getPlaceName:(place_id)->
			return @places.findWhere({id:place_id}).get('name')
		getPlace:(place_id)->
			return @places.findWhere({id:place_id})
		isPlaceCollectionEmpty:()->
			if @places.length == 0
				return true
			else return false
		getPlaceCloneCollection:()->
			return CloneHelper.clone @places
		getPlaceCloneFilteredCollection:(filter)->
			cloneCollection = CloneHelper.clone @places
			filteredPlaces = new FilteredCollection cloneCollection
			if filter?
				filteredPlaces.filterBy('filter',filter)
			filteredPlaces.sort=(comparator)->
				cloneCollection.comparator = comparator
				cloneCollection.sort()
			return filteredPlaces
		getContentCollection:(place_id,flat_collection)->
			isCached= @ContentsCollectionCache?.place_id == place_id
			if isCached
				contents = @ContentsCollectionCache
			else
				if flat_collection
					contents = new ContentEntities.collection null, {place_id:place_id,url:"/core/api/v1/place/helper/content_without_collection/?place_name=#{place_id}"}
				else
					contents = new ContentEntities.collection null,{place_id:place_id}
			contents.fetch() if not isCached
			@ContentsCollectionCache= contents
			return contents
		getFilteredContentCollection:(place_id,filter,flat_collection)->
			contents= @getContentCollection(place_id,flat_collection)
			filteredContent = new FilteredCollection contents
			if filter?
				filteredContent.filterBy('filter',filter)
			return filteredContent
	return new DataManager