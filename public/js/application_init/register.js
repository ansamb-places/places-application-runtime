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
require(['cs!application','jquery.ui','foundation'],function(app){
	$(document).foundation();
	app.initialize();

	$('input[required]').tooltip({
		show:false,
		hide:false,
		disabled:true,
		content:function(){
			return $(this).prop('title')
		},
		position:{
			my: "left center",
			at: "right+10 center"
		},
		tooltipClass: 'p-tooltip',

	}).off("mouseover mouseout").on("input",function(e){
		target= $(e.currentTarget)
		if(target.val().length>0 && target.is(':invalid')){
			target.tooltip( "option", "disabled", false );
			target.tooltip("open");
		}
		else {
			target.tooltip( "option", "disabled", true );
		}
	});
	password1 = $("input[name='password']","#register-form")
	password2 = $("input[name='password-confirm']","#register-form")
	password1.keyup(function(){
		val = password1.val()
		pattern = val.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
		password2.attr("pattern",pattern);
	})

	$("#register-form").submit(function(){
		p1 = password1.val()
		p2 = password2.val()
		if(p1 != p2 || p1 == "" || p2 == ""){
			alert("Passwords mismatch")
			return false
		}
	})
	$("form").on('submit',function(){
		$(".pageload-overlay").show()
		$('form :input').prop("readonly", true);
		$('form :input[type=submit]').prop('disabled', true);
	})
	//setTimeout(function(){$("#loader,#loader::before,#loader::before").show();},2000);
})