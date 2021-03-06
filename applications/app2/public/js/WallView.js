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
// Generated by CoffeeScript 1.6.3
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['ansamb_context', '_css!css/style.css', 'text!views/application.html'], function(c, css, text) {
  var WallView, _ref;
  WallView = (function(_super) {
    __extends(WallView, _super);

    function WallView() {
      this.render = __bind(this.render, this);
      _ref = WallView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    WallView.prototype.initialize = function(options) {
      var placeName;
      placeName = options.placeName || "default";
      console.log(placeName);
      return c.socketio.on("" + placeName + ":message", function(data) {
        return alert(JSON.stringify(data));
      });
    };

    WallView.prototype.render = function() {
      this.$el.empty();
      this.$el.html(text);
      return this;
    };

    return WallView;

  })(Backbone.View);
  return WallView;
});
