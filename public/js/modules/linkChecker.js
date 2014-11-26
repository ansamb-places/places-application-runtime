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
define(['UIBlocker'], function(UIBlocker) {

	/* helper */
	var buildCheckButton=function(cb){
		var button=$("<button class='p-button-round p-background-place p-button tiny'>Check</button>")
		button.on("click",function(){
			cb();
		})
		return button;
	};

	/* variables */
	var link_status = null,
		connected = null,
		connected_defer = $.Deferred();

	/* object handling the check algorithm */
	var linkChecker = {
		timestamp:10000,
		timer:null,
		connect: function(){
			if(linkChecker.timer!=null){
				clearTimeout(linkChecker.timer);
				linkChecker.timer=null;
			}
			var delayConnect = function(){
				linkChecker.timer = setTimeout(linkChecker.connect.bind(linkChecker),linkChecker.timestamp);
			}
			$.get("/core/api/v1/server_link/connect/").done(function(response){
				if(response && response.connected){
					linkChecker.setLinkStatus(response.connected);
					if(response.connected==false){
						delayConnect();
					}
				} else {
					delayConnect()
				}
			}).fail(function(){
				delayConnect()
			});
		},
		setLinkStatus: function(_connected){
			if (_connected === connected) return;
			if(_connected === true){
				connected_defer.resolve();
				UIBlocker.unfreeze();
			}
			else {
				var button = buildCheckButton(linkChecker.connect.bind(linkChecker));
				UIBlocker.freeze("No server connexion. Trying to reconnect ...",true,button);
				linkChecker.connect();
			}
			connected = _connected;
		},
		checkLink: function() {
			if(connected === true) return;
			$.get("/core/api/v1/server_link/status/").done(function(response){
				if(response.err!=null){
					console.log(response.err)
					linkChecker.setLinkStatus(false);
				}
				else{
					linkChecker.setLinkStatus(response.connected);
				}
			}).fail(function(){
				linkChecker.setLinkStatus(false);
			});
		}
	}

	/* public API */
	return {
		init:function(){
			linkChecker.checkLink();
			return connected_defer.promise();
		},
		setLinkStatus:linkChecker.setLinkStatus
	};
});
