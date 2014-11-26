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
	'cs!app'
	'cs!backend_api/ApplicationBackendAPI'
	'cs!backend_api/ContentBackendAPI'
	'cs!entities/Contents'
	'cs!common/views/DialogBoxView'
	'cs!node-webkit/links'
	'cs!node-webkit/saveas'
]
,(App,AppAPI,ContentAPI,ContentEntities,DialogBoxView,nwlinks,nwsaveas)->
	return{
		fileUploadManagement:(files,place_id,collection,options)->
			promise= $.Deferred()
			promise.failed= []
			_.each files,(file,key)=>
				if collection
					content = new ContentEntities.model {
						content_type:'file',
						owner:null,
						read:true,
						data:{name:file.name,mime_type:file.type,filesize:file?.size},
						backend_synced:false,
						uploaded:false
					} 
					collection.add content
				AppAPI.newContent("ansamb_file",place_id,{files:[file],randomize: options?.randomize||false }).done (data)->
					data.backend_synced= true
					content.set data if collection
					content.trigger "change",content if collection
					if key == files.length-1
						promise.resolve()
				.fail (err)=>
					collection.remove content if collection
					if err == "already existing file" or err == "folder"
						promise.failed.push {file: file, type: err}
					if key == files.length-1
						promise.resolve()
			promise.promise()
			promise.done ()=>
				folderError = _.some promise.failed, (fail)-> return fail.type is 'folder'
				if folderError
					@showInfoPopup("Places currently does not support folder transfer")
				else
					if promise.failed.length == 1
						@showConfirmFileUpdateView(promise.failed[0].file,place_id,collection)
					else if promise.failed.length > 1
						file_list= ""
						_.each promise.failed,(fail)->
							file_list= file_list+"<li>#{fail.file.name}</li>"
						@showInfoPopup("The files were not uploaded because they already are in this place, to update them, transfer them one by one <br> <div class='p-info-file-list'>file list: <ul>#{file_list}</ul></div>")

		showConfirmFileUpdateView:(file,place_id,collection)->
			confirmUpdateView = new DialogBoxView {message:"The file #{file.name} is already existing in this place, do you want to update it with your version ?",actions:['cancel','update']}
			confirmUpdateView.on 
				"view:update":()->
					AppAPI.updateContent('ansamb_file',place_id,file).done (data)->
						collection.findWhere({id:data.id}).set data if collection
					.fail ->
						console.log "fail"
			App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show confirmUpdateView
		showInfoPopup:(message)->
			infoPop= new DialogBoxView {message:message,actions:['OK']}
			App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show infoPop
		copyFileToPlace:(place_id, file_id, origin_place_id,cb)->
			#When drag&drop file from a place to a place
			ContentAPI.copyContent(origin_place_id, place_id, file_id).done (content)->
				cb(content) if cb?
			.fail (err)=>
				ContentAPI.getAbsolutePath(origin_place_id,file_id).done (path)=>
					content= App.module("PlacesService").api.getDataManager().ContentsCollectionCache.findWhere({id:file_id})
					file = 
						name:content.get("data").name,
						type:content.get("data").mime_type,
						size:content.get("data").filesize,
						lastModifiedDate:content.get("data").mdate,
						path:path
					@showConfirmFileUpdateView(file,place_id)
		copyFileToConversation:(place_id, file_id, origin_place_id,cb)->
			#When drag&drop file from a place to a ConversationBox
			content= App.module("PlacesService").api.getDataManager().ContentsCollectionCache.findWhere({id:file_id})
			return if content == null
			ContentAPI.getAbsolutePath(origin_place_id,file_id).done (path)->
				file = 
					name:content.get("data").name,
					type:content.get("data").mime_type,
					size:content.get("data").filesize,
					lastModifiedDate:content.get("data").mdate,
					path:path
				AppAPI.newContent("ansamb_file",place_id,{files:[file],randomize:true}).done (data)->
					cb(data) if cb?
				.fail (err)=>
					@showInfoPopup("File is already existing here")
		downloadFiles:(place_id,files)->
			filenames = files.map (file)->
				return file.get('data').name
			nwsaveas.popSaveAs filenames, (download_path)->
				downloadFile = new Array()
				_.each files, (file)->
					downloadProcess = ContentAPI.downloadFile(place_id, file.get('id'), download_path+'/'+file.get('data').name)
					downloadProcess.fail (error)->
						failView = new DialogBoxView {message:error, actions:['ok']}
						App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show failView
					downloadFile.push downloadProcess
				$.when.apply($,downloadFile).done ()->
					nwlinks.openInFinder download_path
		deleteFiles:(place_id,collection,files)->
			confirmView = new DialogBoxView {message:"Do you really want to delete #{ if files.length>1 then 'these files' else 'this file'} ?",actions:['cancel', 'delete']}
			App.dialogRegion.setStyleOptions({borderClass:'p-border-red'}).show confirmView
			confirmView.on "view:delete":->
				_.each files, (file)->
					ContentAPI.deleteContent(place_id,file.get('id')).done (deleted)->
						collection.superset().remove(file)
					.fail (error)->
						alert error
				confirmView.trigger 'close'
			confirmView.on "view:cancel":->
				confirmView.trigger 'close'
		openFileInFinder:(place_id,Content_id)->
			ContentAPI.getAbsolutePath(place_id,Content_id).done(nwlinks.openInFinder)
			.fail (err)->
				alert 'An error occured while trying to open the folder'
				console.log err
	}
