###
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

###
define [''],->
	return (options)->
			return{
				title: options.placeName
				menu:[
                    # {type:'href',name : "files", href : "#place/type/list/#{options.place_id}",item_id:'item/list'},
					{type:'cbButton' ,name : "<span class='p-border-color-content'> add files</span>", cb : null,item_id:'item/add_files'}
					{type:'dropDownView' ,name : "<span class='p-border-color-contact'> contacts<span class=p-ansambers-count> (<span class=ansambers_count></span>)</span></span>", view : null,item_id:'item/contacts'}
				]
				id: 'menu/place/'+options.place_id
				}
	
