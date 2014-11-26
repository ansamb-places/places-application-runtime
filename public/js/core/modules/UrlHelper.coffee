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
define [], ->
	class UrlHelper
		urlTemplateForPlace:_.template("/application/api/v1/router/<%=appName%>/places/<%=place_id%>/<%=url%>")
		urlTemplate:_.template("/application/api/v1/router/<%=appName%>/<%=url%>")
		staticUrlTemplate:_.template("/application/static/<%=appName%>/<%=url%>")
		constructor: (@appName)->
		buildUrl:(url,place_id)->
			if place_id
				return @urlTemplateForPlace({appName: @appName, place_id: place_id, url: url})
			else
				@urlTemplate({appName: @appName, url: url})
		buildStaticUrl:(path)->
			return @staticUrlTemplate({appName: @appName, url: path})
		buildUrlToFile:(place_id,relative_path)->
			relative_path= encodeURIComponent relative_path
			url= "files/"+relative_path
			return @urlTemplateForPlace({appName: @appName, place_id : place_id, url: url})
		buildUrlToStream:(place_id,content_id)->
			return "/core/api/v1/places/#{place_id}/contents/#{content_id}/stream"

