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
var require = {
	paths:{
		'text':'/js/vendor/text',
		'cs':'/js/vendor/cs',
		'_css':'/js/vendor/require-css/css',
		'coffee-script':'/js/vendor/coffee-script',
		'backbone':'/js/vendor/backbone',
		'backbone-marionette':'/js/vendor/backbone.marionette',
		'backbone.wreqr':'/js/vendor/backbone.wreqr.min',
		'backbone.babysitter':'/js/vendor/backbone.babysitter.min',
		'backboneEventStandalone':'/js/vendor/backboneEventStandalone',
		'backbone.nested':'/js/vendor/backbone.nested',
		'backbone-filtered-collection':'/js/vendor/backbone-filtered-collection',
		// 'jquery':'/js/vendor/jquery-2.1.0',
		'jquery':'/js/vendor/jquery',
		'promise':'/js/vendor/promise',
		'underscore':'/js/vendor/underscore',
		'socket.io':'/socket.io/socket.io',
		'moment':'/js/vendor/moment.min',
		'tiptip':'/js/vendor/tipTip.minified',
		'typeahead':'/js/vendor/typeahead.bundle.min',
		'jquery.hotkeys':'/js/vendor/jquery.hotkeys',
		'jquery.fakecrop':'/js/vendor/jquery.fakecrop',
		//'ansamb_context':'modules/ContextModule',
		'async':'/js/vendor/async',
		'jquery.autosize':'/js/vendor/jquery.autosize.min',
		'jquery.autosize.input':'/js/vendor/jquery.autosize.input',
		'jquery.bpopup':'/js/vendor/jquery.bpopup.min',
		'jquery.ui.widget':'/js/vendor/jquery.ui.widget',
		'jquery.iframe-transport':'/js/vendor/jquery-upload/jquery.iframe-transport',
		'jquery.ui':'/js/vendor/jquery-ui.min',
		'jquery.ui-contextmenu':'/js/vendor/jquery.ui-contextmenu.min',
		'modernizr':'/js/vendor/modernizr',
		'jquery.cookie':'/js/vendor/jquery.cookie',
		'mediaElementPlayer':'/js/vendor/mediaelement-and-player.min',
		'hello':'/js/vendor/hello.all',
		/*zurb foundation libs*/
		'foundation':'/js/vendor/foundation/foundation',
		'foundation.dropdown':'/js/vendor/foundation/foundation/foundation.dropdown',
		'foundation.reveal':'/js/vendor/foundation/foundation/foundation.reveal',
		'foundation.equalizer':'/js/vendor/foundation/foundation/foundation.equalizer',
		'foundation.offcanvas':'/js/vendor/foundation/foundation/foundation.offcanvas',
		'foundation.topbar':'/js/vendor/foundation/foundation/foundation.topbar',
		'foundation.magellan':'/js/vendor/foundation/foundation/foundation.magellan',
		'foundation.orbit':'/js/vendor/foundation/foundation/foundation.orbit',
		// node-webkit
		'node-webkit.menu':'/js/core/node-webkit/menu',
		'node-webkit.maximize':'/js/core/node-webkit/maximize',
		'node-webkit.links':'/js/core/node-webkit/links',
		'node-webkit.file':'/js/core/node-webkit/file',
		'node-webkit.window':'/js/core/node-webkit/window',
		// Places Module
		'UIBlocker':'/js/modules/UIBlocker',
		'linkChecker':'/js/modules/linkChecker',
		'contextMenuInterface':'/js/core/modules/interactions/contextMenuInterface',
		'modelfunctionbinder':'/js/core/modules/ModelFunctionBinder',
		'specialViews':'/js/core/modules/specialViews/specialViews'
	},
	shim:{
		backbone:{
			deps:['jquery','underscore'],
			exports:'Backbone'
		},
		'backbone.nested':{
			deps:['backbone','underscore']
		},
		underscore:{
			exports:'_'
		},
		'backbone-filtered-collection':{
			deps:['backbone','underscore']
		},
		jquery:{
			exports:'$'
		},
		'jquery.ui':{
			deps:['jquery']
		},
		'jquery.ui-contextmenu':{
			deps:['jquery.ui']
		},
		'jquery.cookie':{
			deps:['jquery']
		},
		foundation:{
			deps:['jquery','jquery.cookie']
		},
		'foundation.equalizer':{
			deps:['foundation']
		},
		'foundation.offcanvas':{
			deps:['foundation']
		},
		'foundation.orbit':{
			deps:['foundation']
		},
		'foundation.dropdown':{
			deps:['foundation']
		},
		'foundation.reveal':{
			deps:['foundation']
		},
		'foundation.topbar':{
			deps:['foundation']
		},
		'foundation.magellan':{
			deps:['foundation']
		},
		backboneEventStandalone:{
			exports:'BackboneEvents'
		},
		'backbone-marionette':{
			deps:['backbone']
		},
		'contextModule':{
			deps:['RequireManager'] //we need RequireManager loaded to inject it into each context
		},
		'jquery.autosize':{
			deps:['jquery']
		},
		'jquery.autosize.input':{
			deps:['jquery']
		},
		'jquery.bpopup':{
			deps:['jquery']
		},
		'jquery.tablesorter':{
			deps:['jquery']
		},
		'tiptip':{
			deps:['jquery']
		},
		'typeahead':{
			deps:['jquery']
		},
		'mediaElementPlayer':{
			deps:['jquery']
		},
		'jquery.hotkeys':{
			deps:['jquery']
		},
		'jquery.fakecrop':{
			deps:['jquery']
		},
		'UIBlocker':{
			deps:['jquery']
		},
		'linkChecker':{
			deps:['UIBlocker']
		},
		'contextMenuInterface':{
			deps:['backbone-marionette']
		},
		'modelfunctionbinder':{
			deps:['backbone-marionette']
		},
		'specialViews':{
			deps:['backbone-marionette']
		},
		'cs!app':{
			deps:[
				'modernizr',
				'foundation',
				// 'foundation.dropdown',
				'foundation.reveal',
				'foundation.topbar',
				'foundation.magellan',
				'foundation.equalizer',
				'foundation.offcanvas',
				'foundation.orbit',
				'backbone-marionette',
				'contextMenuInterface',
				'modelfunctionbinder',
				'specialViews',
				'promise',
				'_css',
				'backbone.nested',
				'jquery.ui',
				// 'node-webkit.menu',
				'moment',
				'jquery.autosize',
				'jquery.autosize.input',
				'typeahead',
				'jquery.hotkeys',
				'jquery.fakecrop',
				'mediaElementPlayer',
				'UIBlocker'
			]
		}
	}
};