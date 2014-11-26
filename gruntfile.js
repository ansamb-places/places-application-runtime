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
module.exports = function(grunt){
	var root = '.'
	var build_dir = grunt.option('dst') || 'build';
	var target = grunt.option('target') || 'prod';
	var application_dir = 'applications'
	grunt.initConfig({
		copy:{
			core:{
				cwd: root,
				src:[
					'**',
					'!**/*.sqlite',
					'!{gruntfile.js,.gitignore}',
					'!**/*.coffee',
					'!public/**',
					'applications/*/public/**',
					'!test/**'
				],
				dest: build_dir,
				expand: true
			},
			assets:{
				cwd:root,
				src:[
					'public/**',
					'!public/scss/**'
				],
				dest: build_dir,
				expand: true
			}
		},
		clean:{
			build:{
				src:[build_dir+'/**']
			}
		},
		coffee: {
			build: {
				expand: true,
				cwd: root,
				src: [ '**/*.coffee','!public/**','!'+application_dir+'/*/public/**' ],
				dest: build_dir,
				ext: '.js'
			}
		},
		jshint: {
			options:{
				asi:true,
				eqnull:true,
				eqeqeq:false,
				boss:true
			},
			all: ['gruntfile.js', build_dir+'/core/**/*.js']
		},
		compass: {
			dist: {
				options: {
					config: 'public/scss/config.rb',
					environment: 'production',
					force:true,
					outputStyle:'compressed',
					sassDir:'./public/scss/',
					cssDir:build_dir+'/public/css'
				}
			},
			dev:{
				options:{
					config: 'public/scss/config.rb',
					force:true,
					sassDir:'./public/scss/',
					cssDir:build_dir+'/public/css'
				}
			}
		},
		requirejs: {
			compile: {
				options: {
					baseUrl: "public/js/core",
					mainConfigFile: "public/js/core/boot.js",
					name: "app",
					out:build_dir+"/public/js/boot-dist.js",
					findNestedDependencies:true,
					useStrict:false
					// paths:{
					// 	'cs':'js/vendor/cs',
					// }
				}
			}
		},
		mochaTest:{
			unit:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:['test/unit_testing/**/*.test.coffee']
			},
			framework:{
				options:{
					reporter:'nyan',
					require:['coffee-script/register']
				},
				src:['test/framework_testing/**/*.test.coffee']
			},
			account:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:'test/framework_testing/api.account.test.coffee'
			},
			db_models:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:['test/db_models/ansamber_models.test.coffee']
			},
			contact:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:['test/framework_testing/api.contact.test.coffee']
			},
			place:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:['test/framework_testing/api.place.test.coffee']
			},
			place_ansamber:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:['test/framework_testing/api.place.ansamber.test.coffee']
			},
			place_content:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:['test/framework_testing/api.place.content.test.coffee']
			},
			place_message:{
				options:{
					reporter:'spec',
					require:['coffee-script/register']
				},
				src:['test/framework_testing/api.place.message.test.coffee']
			}
		}
	});

	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-coffee');
	// grunt.loadNpmTasks('grunt-contrib-jshint');
	grunt.loadNpmTasks('grunt-contrib-compass');
	grunt.loadNpmTasks('grunt-contrib-requirejs');
	grunt.loadNpmTasks('grunt-mocha-test');

	grunt.registerTask(
		'build', 
		'Compiles all of the assets and copies the files to the build directory.', 
		[ 'clean', 'copy', 'coffee','compass:dist']
	);

	grunt.registerTask('test','Launch all tests',['mochaTest']);
}
