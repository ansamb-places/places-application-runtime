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
module.exports = (database,cb)->
	console.log "database seed"
	cb(null)

###
	RAW SQL QUERIES
###
###
	CONTACT + PLACE
- create a contact
insert into contacts('uid','request_id','created_at','updated_at','status') values('test','45454545','2014-03-05 11:31:39','2014-03-05 11:31:39','validated');

- create a place
insert into places('name','displayed_name','type','owner_uid','created_at','updated_at') values('share.test@rudy14','test','share','rudy14','2014-03-05 11:31:39','2014-03-05 11:31:39');

-associate the contact and the place
insert into contactPlaceJoin('place_id','contact_id','status','request_id','created_at','updated_at') values('1','test','validated','4545455','2014-03-05 11:31:39','2014-03-05 11:31:39');

-get all place I own or shared with me (status=validated)
select distinct places.*,owner.uid from places,contacts,contactPlaceJoin where contacts.uid='test' and ((contactPlaceJoin.contact_id=contacts.uid and places.id=contactPlaceJoin.place_id and contactPlaceJoin.status='validated') or owner_uid=contacts.uid);
###