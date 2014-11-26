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
require(['cs!application','jquery.ui'],function(app){
	app.initialize();
	$(document).ready(function(){
		$("a[data-confirm]").click(function(e){
			message = $(this).data('confirm')
			return confirm(message);
		});
		$("#resend_code").click(function( event ) {
			event.preventDefault();
			// Get some values from elements on the page:
			var password = $("#password").val();
			$("#sending").show()
			$.post("/resend_code/", {password: password}).done(function( data ) {
				if(data.err === null ){
					if(data.service_err === null){
						alert("A new email has been sent to you, please check your email box");
					}
					else{
						alert(data.service_err||"An error has occured, please try again");
					}
				}
				else
					alert(data.err||"An error has occured, please try again");
				$("#sending").hide();
			}).fail(function( data ) {
				$("#sending").hide()
				alert('failed to send the request')
			});
		});
	});
})