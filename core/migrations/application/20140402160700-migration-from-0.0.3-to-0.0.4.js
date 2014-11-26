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
module.exports = {
  up: function(migration, DataTypes, done) {
  	migration.addColumn('places','request_id',{
      type:DataTypes.STRING,
      allowNull:true,
      defaultValue:null
    }).success(function(res){
		  console.log("Migration to v0.0.4: Added request_id into table places",res);
      done()
    });
    // add altering commands here, calling 'done' when finished
  },
  down: function(migration, DataTypes, done) {
    // add reverting commands here, calling 'done' when finished
    done()
  }
}