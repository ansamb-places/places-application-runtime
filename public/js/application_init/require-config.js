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
var require={
	baseUrl:'/js/application_init/',
	paths:{
		'cs':'/js/vendor/cs',
		'coffee-script':'/js/vendor/coffee-script',
		'jquery':'/js/vendor/jquery-2.1.0',
		'underscore':'/js/vendor/underscore',
		'jquery.ui':'/js/vendor/jquery-ui.min',
		'foundation':'/js/vendor/foundation/foundation',
		// Places Module
		'UIBlocker':'/js/modules/UIBlocker',
		'linkChecker':'/js/modules/linkChecker'
		// 'foundation.reveal':'/js/vendor/foundation/foundation/foundation.reveal'
	},
	shim:{
		jquery:{
			exports:'$'
		},
		'jquery.ui':{
			deps:['jquery']
		},
		foundation:{
			deps:['jquery']
		},
		'UIBlocker':{
			deps:['jquery']
		},
		'linkChecker':{
			deps:['UIBlocker']
		}
	}
}