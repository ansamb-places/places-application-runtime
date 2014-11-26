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
	'moment'
	'cs!backend_api/ContentBackendAPI'
	'cs!modules/CollectionFetchInterface'
	],(moment,ContentAPI,CollectionFetchInterface)->
	convertSizeToReadable=(size)->
		i = 0
		byteUnits = [' B',' kB', ' MB', ' GB', ' TB', 'PB', 'EB', 'ZB', 'YB']
		while size>1024
			size = size / 1024
			i++
		return Math.max(size, 0.1).toFixed(1) + byteUnits[i]
	setStateOnEvent=(model,e)->
		switch e
			when 'download:end'
				model.set 'downloaded',true
			when 'upload:end'
				model.set 'uploaded',true

	class Content extends Backbone.NestedModel
		idAttribute:"_id"
		defaults:
			id:null
			backend_synced:true
			downloaded:true
			new:false
		name:->
			return @get('data').filename.replace(/.[^.]+$/,'')
		ext:->
			return @get('data').filename.replace(/^.*\./,'')
		format:->
			formatedObject= @toJSON()
			formatedObject.date= moment(formatedObject.date).format('MM/DD/YY hh:mm')
			if not isNaN(+@get('data.filesize'))
				formatedObject.data.filesize= convertSizeToReadable +formatedObject.data.filesize
			return formatedObject
		initialize:(options)->
			super(options)
	class Contents extends Backbone.Collection
		constructor:(models,options)->
			if options
				@place_id = options.place_id||"default"
				if options.url
					@url = options.url
				else
					@url = "/core/api/v1/places/#{@place_id}/contents/"
			super(models,options)
			_.extend @,CollectionFetchInterface
		model:Content
		initialize:(models,options)->
			@listenTo @,'change:downloaded',@checkDownloaded
			@listenTo @,'add',@onModelAdded_changed
			@listenTo @,'change',@onModelAdded_changed
			@listenTo @,"download:end",_.partial(@stateUpdate,"download:end")
			@listenTo @,"upload:end",_.partial(@stateUpdate,"upload:end")
			@state_promises = {}
		setStateListener:(model,isCollection)->
			if isCollection
				model.each (model)=>@setStateListener model,false
			else
				@state_promises[model.get('id')] = $.Deferred()
				@state_promises[model.get('id')].done (e)->
					setStateOnEvent(model,e)
		onModelAdded_changed:(model)->
			return if (@checkDownloaded(model) and model.get('uploaded')) or !model.get('id')
			if !@state_promises[model.get('id')] or (model.changedAttributes("downloaded") and !model.get("downloaded")) or (model.changedAttributes("uploaded") and !model.get("uploaded"))
				@setStateListener(model,false)
			else
				@state_promises[model.get('id')].done (e)->
					setStateOnEvent(model,e)
		parse:(response)->
			return response.data
		setPlaceName:(place_id)->
			@place_id = place_id
			@url = "/core/api/v1/places/#{place_id}/contents/"
		checkDownloaded:(model)->
			if not model.get('downloaded')
				ContentAPI.downloadContent(@place_id,model.get('id'))
				return false
			return true
	return {model:Content,collection:Contents}