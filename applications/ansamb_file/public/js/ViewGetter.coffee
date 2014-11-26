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
	'cs!js/AudioView',
	'cs!js/VideoView',
	'cs!js/PictureView',
	'cs!js/PdfView',
	'cs!js/DefaultView'
	],(AudioView,VideoView,PictureView,PdfView,DefaultView)->
		_config = 
			video: ['video/mp4','video/m4v','video/mov','video/flv','video/rtmp','video/x-flv','video/ogg','video/quicktime']
			audio: ['audio/ogg','audio/wma','audio/m4a','audio/mp3','audio/wav','audio/flv','audio/x-flv','audio/mpeg']
			pdf: ['application/pdf']
			picture:['image/jpeg','image/png','image/gif']
		_Views = 
			video: VideoView
			audio: AudioView
			pdf: PdfView
			picture: PictureView
			default: DefaultView
		getView=(mime_type)->
			matchView = null
			_.each _config,(item,key)=>
				if item.indexOf(mime_type)+1
					matchView = _Views[key] || null
			if matchView == null
				matchView = DefaultView
			return matchView
		return getView

