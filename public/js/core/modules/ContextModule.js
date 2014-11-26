/*
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

*/
define(['module','socket.io','cs!urlHelper'],function(module,io,uh){
	var appName = module.config().appName;
	var s = io.connect("/"+appName);
	var urlHelper= new uh(appName);
	baseUrl="/application/api/v1/router/"+appName;
	return {
		socketio:s,
		baseUrl:baseUrl,
		urlHelper:urlHelper,
		PathTo:function(place_id){
			if(arguments.length==0)
				return this.baseUrl;
			return baseUrl+"/places/"+placeName+"/";
		},
		createPopup:function(view){
			window.mainApp.popupRegion.show(view);
		},
		createDialog:function(view){
			window.mainApp.dialogRegion.setStyleOptions({borderClass:'p-border-red', closeButton:true}).show(view);
		},
		appName:appName,
		mainApplication:window.mainApp||null,
		_require:appName!=""?window._require(appName):null
	};
});