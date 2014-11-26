// Intravenous JavaScript library v0.1.4-beta
// (c) Roy Jacobs
// License: MIT (http://www.opensource.org/licenses/mit-license.php)

(function(window,undefined){
var j=!0,k=null;function m(h){function p(a,b,d){for(var c=q(a,b),b=c.key,c=c.data,e,f=a;f&&!(e=f.k[b]);)f=f.parent;if(c&&c.s){var g=c.s(a,b,e);if(g.i)return g.data}if(!f)throw Error("Unknown dependency: "+b);if(c&&c.u&&(g=c.u(a,b,e),g.i))return g.data;if(c=a.c[e.m].get(b))return c;var i;if(e.value instanceof Function){c=e.value.$inject;i=[];if(c instanceof Array){f=0;for(g=c.length;f<g;f++)i.push(p(a,c[f],[]))}c=function(){};c.prototype=e.value.prototype;c=new c;f=0;for(g=d.length;f<g;f++)i.push(d[f]);i=e.value.apply(c,
i);if(i instanceof Function){c=new l(a,b);c.a.j(b,i);for(var h in i)i.hasOwnProperty(h)&&(c[h]=i[h]);i=void 0}}else c=e.value;a.c[e.m].set(new w(e,c));return i||c}function q(a,b){for(var d in a.t)for(var c=a.t[d],e=0,f=c.suffixes.length;e<f;e++){var g=c.suffixes[e];if(-1!==b.indexOf(g,b.length-g.length))return{data:c,key:b.slice(0,b.length-g.length)}}return{data:k,key:b}}function n(a,b){this.k={};this.parent=b;this.c={perRequest:new r(this),singleton:new s(this,b?b.c.singleton:k),unique:new t(this)};
this.children=[];this.options=a=a||{};this.j("container",this);this.dispose=this.g;this.get=this.get;this.register=this.j}function u(a,b){this.a=a;this.key=b;this.dispose=this.g;this.get=this.get;this.use=this.l}function l(a,b){this.a=a.create();this.key=b;this.dispose=this.g;this.get=this.get;this.use=this.l}function t(a){this.a=a;this.b=[]}function s(a,b){this.a=a;this.b=[];this.f={};this.parent=b}function r(a){this.a=a;this.b=[];this.f={};this.e=0;this.p={};this.q=[]}function w(a,b){this.d=a;this.h=
b}function x(a,b,d,c){this.key=a;this.a=b;this.value=d;this.m=c}function v(a,b){for(var d=a.split("."),c=h,e=0;e<d.length-1;e++)c=c[d[e]];c[d[d.length-1]]=b}h="undefined"!==typeof h?h:{};h.version="0.1.4-beta";v("version",h.version);r.prototype={get:function(a){for(var b=0,d=this.b.length;b<d;b++){var c=this.b[b];if(c.d.key===a&&c.e===this.e){if(!c.h)break;this.set(c);return c.h}}this.q.push(a);if(this.p[a])throw Error("Circular reference: "+this.q.join(" --\> "));this.p[a]=j;return k},set:function(a){this.b.push(a);
a.e=this.e;this.f[a.e]=this.f[a.e]||{};this.f[a.e][a.d.key]=this.f[a.e][a.d.key]++||1},n:function(a){return!--this.f[a.e][a.d.key]},o:function(){this.e++;this.p={};this.q=[]}};s.prototype={get:function(a){for(var b=0,d=this.b.length;b<d;b++){var c=this.b[b];if(c.d.key===a){if(!c.h)break;this.set(c);return c.h}}return this.parent?this.parent.get(a):k},set:function(a){this.b.push(a);this.f[a.d.key]=this.f[a.d.key]++||1},n:function(a){return!--this.f[a.d.key]},o:function(){}};t.prototype={get:function(){return k},
set:function(a){this.b.push(a)},n:function(){return j},o:function(){}};l.prototype={get:function(){var a=Array.prototype.slice.call(arguments);a.unshift(this.key);a=this.a.get.apply(this.a,a);a.r=this;return a},l:function(a,b,d){this.a.j(a,b,d);return this},g:function(){this.a.g()}};u.prototype={get:function(){var a=new l(this.a,this.key);return a.get.apply(a,arguments)},l:function(a,b,d){return(new l(this.a,this.key)).l(a,b,d)},g:function(a){a.r.g();delete a.r}};n.prototype={t:{w:{suffixes:["?"],
s:function(a,b,d){return d?{i:!1}:{i:j,data:k}}},factory:{suffixes:["Factory","!"],u:function(a,b){return{i:j,data:new u(a,b)}}}},j:function(a,b,d){if(q(this,a).data)throw Error("Cannot register dependency: "+a);!d&&this.k[a]?this.k[a].value=b:this.k[a]=new x(a,this,b,d||"perRequest")},get:function(a){for(var b in this.c)this.c.hasOwnProperty(b)&&this.c[b].o(a);b=Array.prototype.slice.call(arguments).slice(1);for(var d=this,c;d&&(c=p(d,a,b))===k;)d=d.parent;return c},g:function(){for(var a;a=this.children.pop();)a.g();
for(var b=this.v();a=b.pop();)if(this.c[a.d.m].n(a)&&this.options.onDispose)this.options.onDispose(a.h,a.d.key);return j},create:function(a){a=a||{};a.onDispose=a.onDispose||this.options.onDispose;a=new n(a,this);this.children.push(a);return a},v:function(){var a=[],b;for(b in this.c)this.c.hasOwnProperty(b)&&(a=a.concat(this.c[b].b));return a}};h.create=function(a){return new n(a)};v("create",h.create)}
"function"===typeof require&&"object"===typeof exports&&"object"===typeof module?m(module.exports||exports):"function"===typeof define&&define.amd?define(["exports"],m):m(window.intravenous={});j;
})(typeof window !== "undefined" ? window : global);