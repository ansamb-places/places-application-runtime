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
define(function() {
	var requireJS = window.require
	window.require = require = window.requireNode;
	
	// Load native UI library
	var gui = require('nw.gui');
	var win = gui.Window.get();
	var menubar = new gui.Menu({ type: 'menubar' });
	
	var file = new gui.Menu();
	file.append(new gui.MenuItem({
		label: 'New window',
		click: function() {
			var win = gui.Window.open('http://localhost:8080/app/', {
			    width: 1200,
			    height: 640,
			    toolbar: false,
			    min_width: 1025,
			    min_height: 315
			});
		}
	}));

	var places = new gui.Menu();
	places.append(new gui.MenuItem({
		label: 'New place',
		click: function() {
			window.location = "http://localhost:8080/app/#place/create/";
		}
	}));

	menubar.append(new gui.MenuItem({ label: 'Files', submenu: file}));
	menubar.append(new gui.MenuItem({ label: 'Places', submenu: places}));
	win.menu = menubar;

	window.require = requireJS;
});