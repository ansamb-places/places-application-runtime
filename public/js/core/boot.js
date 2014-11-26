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
require.config({
	baseUrl:'/js/core/'
});

window.bootLoader = new SVGLoader( document.getElementById( 'loader' ), { speedIn : 700, easingIn : mina.easeinout } );

require(['cs!app','linkChecker'],function(App,linkChecker){
	//start foundation framework
	$(document).foundation({
		equalizer: {
	    before_height_change: function(){
	      alert("height change");
	    },
	    after_height_change: function(){
	      // do something after the height changes
    	}
    },
    dropdown:{
    	active_class:'open animated fadeInDown'
    }
    });
	// $(document).foundation('dropdown','off');
	// $(document).foundation('dropdown');

	$.ajaxSetup({cache: false});
	linkChecker.init().done(function(){
		bootLoader.show();
		App.start({placeName:"default"});
	});
});
