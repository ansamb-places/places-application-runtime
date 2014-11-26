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
define [],->
	messages = 
		delete_place:"""Do you want to delete the place? 
			<br/><br/> <span style='color:grey;'> 
			The place will be deleted but its contents will 
				remain on other people devices and won't be 
				automatically deleted. </span>"""
		leave_place: """Do you want to leave the place?
			<br/><br/><span style='color:grey;'> 
			The place and its files will be deleted on your device only
				and other contacts will be notified that you don't
				belong to the place anymore. </span>"""
	return {
		getMessage:(key)->	
			return messages[key] || key || "N/A"
	}