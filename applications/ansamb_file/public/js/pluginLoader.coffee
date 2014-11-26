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
],(c,a5js,vjs)->
	class pluginLoader
		getMediaNewId:->
			return @media_id++
		openFile:(fileName,place_id)->
			#send a request to the node server wich will open file
			$.post c.urlHelper.buildUrl("open/",place_id),{filename:fileName}
		openPdf:(path)->
			window.open(c.urlHelper.buildStaticUrl('public')+"/plugins/web/viewer.html?file="+encodeURIComponent(path),'_blank',"screenX=#{window.screenX+20},screenY=#{window.screenY+20}");
		initMedia:(id,force)->
			mode= 'auto_plugin' if force 
			return player= new MediaElementPlayer('#'+id,{
				mode: mode || "auto",
				plugins: ['flash'],
				type: '',
				pluginPath: '/swf/',
				flashName: 'flashmediaelement.swf'
				})
	return new pluginLoader()
