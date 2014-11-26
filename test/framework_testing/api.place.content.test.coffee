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
expect = require('chai').expect
proxyquire = require 'proxyquire'
sinon = require 'sinon'
async = require 'async'
uuid = require "node-uuid"
path = require "path"
fs = require "fs"
http = require 'http'
_ = require 'underscore'
crypto = require 'crypto'

framework = null
module = null
place_id = null
place_id2 = null

#those tests assume that a place named "mocha_test exists"
place_name = "mocha_test"+new Date()
place_name2 = "mocha_test2"+new Date()
fake_content =
	id:uuid.v4()
	content_type:"post"
	ref_content:null
	notify_ui:false
	emit_network:true
	read:true

# fake_file = "id": "fd46819a24ffe0ba3b408b8d563b33d33f89a2c69768a86e95befbd738129238",
# 		{
# 		"name": "image4.pdf",
# 		"filesize": 40427,
# 		"mime_type": "application/pdf",
# 		"mdate": "2014-03-27 08:53:32",
# 		"relative_path": "image4.pdf",
# 		"content_id": "fd46819a24ffe0ba3b408b8d563b33d33f89a2c69768a86e95befbd738129238",
# 		"created_at": "2014-06-17 13:35:24",
# 		"updated_at": "2014-06-17 13:35:24"
# 		}

describe 'api.place.content lib',->
	
	before (done)->
		@timeout(5000)
		core = require process.cwd()
		core.defer.promise.then (_framework)->
			framework = _framework
			module = framework.getService("api.place.content")
			framework.getService("api.account").getAccount ->
				#create test place
				place_id = framework.getService("api.place").createPlaceId("share",null,null).place_id
				place_id2 = framework.getService("api.place").createPlaceId("share",null,null).place_id
				framework.getService("api.place").addPlace {
					id:place_id
					name:place_name
					type:"share"
					owner_uid:null
				},{wait_validation:true},(err,_place)->
					expect(err).to.be.null
					expect(_place).to.be.an("object")
					framework.getService("api.place").addPlace {
						id:place_id2
						name:place_name2
						type:"share"
						owner_uid:null
					},{wait_validation:true},(err,_place)->
						expect(err).to.be.null
						expect(_place).to.be.an("object")
						#disable route filtering
						framework.getService("server").stepManager.disableFiltering()
						done()
	after (done)->
		async.waterfall [
			(callback)->
				framework.getService("api.place").deletePlaceById place_id,callback
			(deleted,callback)->
				framework.getService("api.place").deletePlaceById place_id2,callback
		],(err,deleted)->
			expect(err).to.be.null
			done()

	describe 'delete content',->
		delete_content_fake_content = _.clone(fake_content)
		delete_content_fake_content.id = uuid.v4()

		it 'the test configuration should be ok',->
			expect(framework).to.be.an("object")
			expect(place_id).to.be.not.null

		it 'should correctly load the lib',->
			expect(module).to.be.an("object")

		it 'should call the deleteContent method of content_manager to delete metadatas',(done)->
			content_id = null
			#create a new content first
			module._addContentToPlace place_id,delete_content_fake_content,{post:"ok"},(err,content)->
				expect(err).to.be.null
				content_id = content.id
				content_manager = framework.getService("content_manager")
				spy = sinon.spy(content_manager,"deleteContent")
				module._deleteContentOfPlace place_id,{id:content_id,emit_network:false},(err,deleted)->
					expect(spy.withArgs(place_id,sinon.match({id:content_id})).calledOnce).to.be.true
					expect(err).to.be.null
					expect(deleted).to.be.true
					content_manager.deleteContent.restore()
					done()

		it 'should call the delete method of application.broker crud interface to delete the application content',(done)->
			content_id = null
			#create a new content first
			module._addContentToPlace place_id,delete_content_fake_content,{post:"ok"},(err,content)->
				expect(err).to.be.null
				content_id = content.id
				application_broker = framework.getService("application.broker")
				spy = sinon.spy(application_broker.api.crud,"delete")
				module._deleteContentOfPlace place_id,{id:content_id,emit_network:false},(err,deleted)->
					expect(spy.withArgs(place_id,sinon.match({id:content_id})).calledOnce).to.be.true
					expect(err).to.be.null
					expect(deleted).to.be.true
					application_broker.api.crud.delete.restore()
					done()

		it 'the content should not appear anymore into databases',(done)->
			module._addContentToPlace place_id,delete_content_fake_content,{post:"ok"},(err,content)->
				expect(err).to.be.null
				content_id = content.id
				module._deleteContentOfPlace place_id,{id:content_id,emit_network:false},(err,deleted)->
					expect(err).to.be.null
					expect(deleted).to.be.true
					module.getContentForPlace place_id,(err,contents)->
						for c in contents
							expect(c.id).to.not.be.equal(content_id)
						done()

		it 'should trigger a delete event through the event service',(done)->
			events = framework.getService("events")
			spy = sinon.spy(events.emitter,"emit")
			module._addContentToPlace place_id,delete_content_fake_content,{post:"ok"},(err,content)->
				content_id = content.id
				module._deleteContentOfPlace place_id,{id:content_id,emit_network:false},(err,deleted)->
					expect(spy.withArgs("content:delete",sinon.match({id:place_id}),content_id).calledOnce).to.be.true
					events.emitter.emit.restore()
					done()

		it 'should send a network message if the option is set and get the correct reply',(done)->
			service = framework.getService("protocol.builder").content
			originalDelete = service.deleteRequest
			sendSpy = null
			stub = sinon.stub service,"deleteRequest",->
				obj = originalDelete.apply null,arguments
				sendSpy = sinon.spy()
				obj.send = ->
					obj.communication_layer.send.call null,obj.message,sendSpy
				return obj
			module._addContentToPlace place_id,delete_content_fake_content,{post:"ok"},(err,content)->
				content_id = content.id
				module._deleteContentOfPlace place_id,{id:content_id,emit_network:true},(err,deleted)->
					setTimeout ->
						expect(stub.withArgs(sinon.match({content_id:content_id})).calledOnce).to.be.true
						expect(sendSpy.withArgs(null,sinon.match({content_id:content_id,code:200})).calledOnce).to.be.true
						service.deleteRequest.restore()
						done()
					,100

		it 'should call the delete method of api.place.content when receiving the corresponding network message',->
			mock = sinon.mock(module)
			mock.expects("_deleteContentOfPlace").once().withArgs(place_id,sinon.match({id:'e501e896-cc3c-4d4f-bd8b-c52493b52ed0'}))
			framework.getService("communication_layer").inject({
				src:'ansamb',
				dst: '*',
				method: 'DELETE',
				spl: place_id,
				dpl: place_id,
				content_id: 'e501e896-cc3c-4d4f-bd8b-c52493b52ed0',
				rev: 'd9bd800c-41ab-4a3e-a054-f14f20466297',
				ver: 1,
				protocol: 'content',
				message_id: 'b9c7119f-87c7-4193-8515-774be56ade1a'
			})
			mock.verify()
			mock.restore()

	describe 'util methods',->
		describe 'file absolute path',->
			it 'should return an error if options is missing',(done)->
				module.generateAbsoluteFilePath "test",{},(err,path)->
					expect(err).to.not.be.null
					done()
			it 'should generate an absolute path given a relative path and a content_type',(done)->
				name = "test.mp4"
				module.generateAbsoluteFilePath place_id,{relative_path:name,content_type:"file"},(err,path)->
					expect(err).to.be.null
					expect(path).to.satisfy (item)->
						return item.indexOf(name)!=-1
					done()

	describe 'copy content',->
		_content = null
		_data = null

		copy_content_fake_content = _.clone(fake_content)
		copy_content_fake_content.id = uuid.v4()

		before (done)->
			framework.getService("api.place").getPlaceFromName place_name2,(err,place)->
				expect(err).to.be.null
				expect(place).to.be.an("object")
				expect(place_id).to.not.be.null
				place_id2 = place.id
				module._addContentToPlace place_id,copy_content_fake_content,{post:"ok"},(err,content,data)->
					expect(err).to.be.null
					expect(content).to.be.an("object")
					expect(data).to.be.an("object")
					_content = content
					_data = data
					done()

		after (done)->
			console.log "running content delete"
			module._deleteContentOfPlace place_id,{id:_content.id,emit_network:false},(err)->
				done()

		it 'should return an error if the source place not exists',(done)->
			module.copyContent "___place",place_id,"ffff",(err,copied_object)->
				expect(err).to.not.be.null
				done()

		it 'should return an error if the destination place not exists',(done)->
			module.copyContent place_id,"___place","ffff",(err,copied_object)->
				expect(err).to.not.be.null
				done()

		it 'should return an error if the content id not exists',(done)->
			module.copyContent place_id,place_id2,"ffff",(err,copied_object)->
				expect(err).to.not.be.null
				done()

		it 'should return an error if the destination place not exists',(done)->
			module.copyContent "___place1","____place2","ffff",(err,copied_object)->
				expect(err).to.not.be.null
				done()

		it 'should return the copied content',(done)->
			module.copyContent place_id,place_id2,_content.id,(err,content,data)->
				expect(err).to.be.null
				expect(content).to.be.an("object").that.have.property('rev',_content.rev)
				expect(data).to.have.property("id",content.id)
				module._deleteContentOfPlace place_id2,{id:content.id,emit_network:false},->
					done()

		it 'should copy the file on file system if the content is a file',(done)->			
			# ++++++ SETUP +++++++
			@timeout(3000)
			original_file_path = path.join __dirname,"files/image4.pdf"
			name = "image#{+new Date()}.pdf"
			dst_path = path.join path.dirname(original_file_path),name
			file =
				path:dst_path
				name:name
				size:40000
				type:"application/pdf"
				lastModifiedDate:new Date()
			post_data = JSON.stringify {files:[file]}
			post_options =
				host:"localhost"
				port:8080
				path:"/application/api/v1/router/ansamb_file/places/#{place_id}/"
				method:"POST"
				headers:
					"Content-Type":"application/json"
					"Content-Length":post_data.length
			#copy file
			fs.writeFileSync(dst_path,fs.readFileSync(original_file_path))
			# +++++++++ END SETUP +++++++++++

			deleteContent = (p_id,c_id,cb)->
				module._deleteContentOfPlace p_id,{id:c_id,emit_network:false},cb
			content_id1 = null
			content_id2 = null
			async.waterfall [
				(callback)->
					#create a file content
					req = http.request post_options,(res)->
						res.setEncoding 'utf8'
						resp = ""
						res.on 'data',(chunk)->
							resp += chunk
						res.on 'end',->
							reply  = JSON.parse(resp)
							callback null,reply.data
					req.on 'error',callback
					req.write(post_data)
					req.end()
				(content,callback)->
					expect(content).to.be.an("object").that.have.property("id")
					content_id1 = content.id
					module.copyContent place_id,place_id2,content.id,(err,content2,data2)->
						expect(err).to.be.null
						expect(content2).to.be.an("object").that.have.property("id",content.id)
						expect(data2).to.be.an("object").that.have.property("relative_path")
						return callback err if err?
						content_id2 = content2.id
						p_options = 
							relative_path:data2.relative_path
							content_type:content2.content_type
						module.generateAbsoluteFilePath place_id2,p_options,(err,final_path)->
							return callback err if err?
							return callback "moved file not found" if not fs.existsSync(final_path)
							callback null
			],(err)->
				async.parallel [
					(callback)->
						return callback null if content_id1==null
						deleteContent place_id,content_id1,(err,deleted)->
							callback err
					(callback)->
						return callback null if content_id2==null
						deleteContent place_id2,content_id2,(err,deleted)->
							callback err
					(callback)->
						fs.unlink dst_path,(err)->
							callback err
				],(delete_err)->
					expect(err).to.be.null
					expect(delete_err).to.be.null
					done()

		it 'should change the content_id if the content is not a file',(done)->
			module.copyContent place_id,place_id2,_content.id,(err,content,data)->
				expect(err).to.be.null
				expect(content.id).to.not.be.equal(_content.id)
				done()

		it 'should send a network message',(done)->
			service = framework.getService("protocol.builder").content
			original = service.putRequest
			spy = sinon.spy service,"putRequest"
			module.copyContent place_id,place_id2,_content.id,(err,content,data)->
				expect(spy.withArgs(sinon.match({content_id:content.id,place:place_id2})).calledOnce).to.be.true
				service.putRequest.restore()
				done()

	describe 'upload file',->
		# ++++++ SETUP +++++++
		@timeout(3000)
		original_file_path = path.join __dirname,"files/image4.pdf"
		name = "image#{+new Date()}.pdf"
		dst_path = path.join path.dirname(original_file_path),name
		content= null
		before (done)->
			file =
				path:dst_path
				name:name
				size:40000
				type:"application/pdf"
				lastModifiedDate:new Date()
			post_data = JSON.stringify {files:[file]}
			post_options =
				host:"localhost"
				port:8080
				path:"/application/api/v1/router/ansamb_file/places/#{place_id}/"
				method:"POST"
				headers:
					"Content-Type":"application/json"
					"Content-Length":post_data.length
			fs.writeFileSync(dst_path,fs.readFileSync(original_file_path))
			req = http.request post_options,(res)->
				res.setEncoding 'utf8'
				resp = ""
				res.on 'data',(chunk)->
					resp += chunk
				res.on 'end',->
					content = JSON.parse(resp).data
					done()
			req.on 'error',(e)->
				throw e
				done()
			req.write(post_data)
			req.end()
		after (done)->
			module._deleteContentOfPlace place_id,{id:content.id,emit_network:false},(err)->
				fs.unlinkSync dst_path
				done()
		afterEach (done)->
			framework.getService("content_manager").updateContentOnly place_id,{id:content.id,uploaded:false},(err,_content)->
				expect(err).to.be.null
				content= _content
				done()

		it 'the uploaded state should be false initially',->
			expect(content.uploaded).to.be.false

		it 'should change the database model',(done)->
			module.handleUploadEnd place_id,content.id,(err)->
				expect(err).to.be.null
				framework.getService("content_manager").getContentById place_id,content.id,{raw:false,unmarshall:false},(err,content)->
					expect(err).to.be.null
					expect(content).not.to.be.null
					expect(content.uploaded).to.be.true
					done()
		it 'should trigger callback with err when wrong place_id is used',(done)->
			module.handleUploadEnd "wrong_place_id",content.id,(err)->
				expect(err).not.to.be.null
				done()

		it 'should trigger callback with err when wrong place_id is used',(done)->
			module.handleUploadEnd place_id,"wrong_content_id",(err)->
				expect(err).not.to.be.null
				done()

		it 'should call Once on message from kernel',(done)->
			spy = sinon.spy(module,"handleUploadEnd")
			message = 
				message_id:"111111"
				protocol:"fs"
				method:"UPLOAD"
				date:+new Date
				spl:place_id
				dpl:place_id
				content_id:content.id
				code:200
			framework.getService("communication_layer").inject message
			setTimeout ->
				module.handleUploadEnd.restore()
				expect(spy.withArgs(place_id,content.id).calledOnce).to.be.true
				done()
			,300

		it 'should trigger an event on through the event service',(done)->
			events = framework.getService("events")
			spy = sinon.spy(events.emitter,"emit")
			message = 
				message_id:"111111"
				protocol:"fs"
				method:"UPLOAD"
				date:+new Date
				spl:place_id
				dpl:place_id
				content_id:content.id
				code:200
			framework.getService("communication_layer").inject message
			setTimeout ->
				events.emitter.emit.restore()
				expect(spy.withArgs("upload:end",place_id,content.id).calledOnce).to.be.true
				done()
			,300

	describe 'rename file',->
		# ++++++ SETUP +++++++
		@timeout(3000)
		original_file_path = path.join __dirname,"files/image4.pdf"
		name = "image#{+new Date()}.pdf"
		new_relative_path= "renamed_"+name
		dst_path = path.join path.dirname(original_file_path),name
		content= null
		new_path= path.join path.dirname(original_file_path),new_relative_path
		sha = crypto.createHash('sha256')
		sha.update(new_relative_path,'utf8')
		new_id = sha.digest('hex')
		beforeEach (done)->
			file =
				path:dst_path
				name:name
				size:40000
				type:"application/pdf"
				lastModifiedDate:new Date()
			post_data = JSON.stringify {files:[file]}
			post_options =
				host:"localhost"
				port:8080
				path:"/application/api/v1/router/ansamb_file/places/#{place_id}/"
				method:"POST"
				headers:
					"Content-Type":"application/json"
					"Content-Length":post_data.length
			fs.writeFileSync(dst_path,fs.readFileSync(original_file_path))
			req = http.request post_options,(res)->
				res.setEncoding 'utf8'
				resp = ""
				res.on 'data',(chunk)->
					resp += chunk
				res.on 'end',->
					content = JSON.parse(resp).data
					done()
			req.on 'error',(e)->
				throw e
				done()
			req.write(post_data)
			req.end()
		afterEach (done)->
			module._deleteContentOfPlace place_id,{id:content.id,emit_network:false},(err)->
				module._deleteContentOfPlace place_id,{id:new_id,emit_network:false},(err)->
					done()

		it 'should change the database model',(done)->
			module.renameFileContent place_id,{old_content_id:content.id,new_relative_path:new_relative_path,content_type:'file'},(err)->
				expect(err).to.be.null
				module.getContentById place_id,new_id,{raw:false,unmarshall:false},(err,content)->
					expect(err).to.be.null
					expect(content).not.to.be.null
					expect(content.data.name).to.be.equal(new_relative_path)
					expect(content.data.relative_path).to.be.equal(new_relative_path)
					expect(content.data.id).to.be.equal(new_id)
					expect(content.dataValues.id).to.be.equal(new_id)
					done()
		it 'should change the filename on the system',(done)->
			module.renameFileContent place_id,{old_content_id:content.id,new_relative_path:new_relative_path,content_type:'file'},(err)->
				expect(err).to.be.null
				module.generateAbsoluteFilePath place_id,{content_type:'file',relative_path:new_relative_path},(err,path)->
					expect(err).to.be.null
					expect(fs.existsSync(path)).to.be.true
					done()
		it 'should trigger callback with err when wrong place_id is used',(done)->
			module.renameFileContent "place_id",{old_content_id:content.id,new_relative_path:new_relative_path,content_type:'file'},(err)->
				expect(err).not.to.be.null
				done()
		it 'should trigger callback with err when wrong content_id is used',(done)->
			module.renameFileContent place_id,{old_content_id:"content.id",new_relative_path:new_relative_path,content_type:'file'},(err)->
				expect(err).not.to.be.null
				done()
		it 'should trigger callback with err if already exist file',(done)->
			cb=->
				module.renameFileContent place_id,{old_content_id:content.id,new_relative_path:new_relative_path,content_type:'file'},(err)->
					expect(err).not.to.be.null
					done()
			file =
				path:new_path
				name:new_relative_path
				size:40000
				type:"application/pdf"
				lastModifiedDate:new Date()
			post_data = JSON.stringify {files:[file]}
			post_options =
				host:"localhost"
				port:8080
				path:"/application/api/v1/router/ansamb_file/places/#{place_id}/"
				method:"POST"
				headers:
					"Content-Type":"application/json"
					"Content-Length":post_data.length
			fs.writeFileSync(new_path,fs.readFileSync(original_file_path))
			req = http.request post_options,(res)->
				res.setEncoding 'utf8'
				resp = ""
				res.on 'data',(chunk)->
					resp += chunk
				res.on 'end',->
					cb()
			req.on 'error',(e)->
				throw e
				cb()
			req.write(post_data)
			req.end()

		it 'should emit a network message',(done)->
			service = framework.getService("protocol.builder").content
			originalRename = service.renameRequest
			sendSpy = null
			stub = sinon.stub service,"renameRequest",->
				obj = originalRename.apply null,arguments
				obj.send = (cb)->
					sendSpy = sinon.spy(cb)
					obj.communication_layer.send.call null,obj.message,sendSpy
				return obj
			module.renameFileContent place_id,{old_content_id:content.id,new_relative_path:new_relative_path,content_type:'file',emit_network:true},(err)->
				expect(stub.withArgs(sinon.match({place:place_id,old_content_id:content.id,content_type:'file',relative_path:new_relative_path,new_content_id:new_id})).calledOnce).to.be.true
				expect(sendSpy.withArgs(null,sinon.match({content_id:content.id,code:200})).calledOnce).to.be.true
				service.renameRequest.restore()
				done()

		it 'should call renameFileContent methods once on message from network',(done)->
			spy = sinon.spy(module,"renameFileContent")
			message = 
				message_id:"111111"
				protocol:"content"
				method:"RENAME"
				date:+new Date
				spl:place_id
				dpl:place_id
				content_id:content.id
				content_type:'file'
				data:
					relative_path:new_relative_path
					new_content_id:new_id
				code:200
			framework.getService("communication_layer").inject message
			setTimeout ->
				module.renameFileContent.restore()
				expect(spy.withArgs(place_id,sinon.match({old_content_id:content.id,new_content_id:new_id,new_relative_path:new_relative_path,content_type:'file',emit_network:false})).calledOnce).to.be.true
				done()
			,300
		it 'should emit message through the event service when message is from the network',(done)->
			events = framework.getService("events")
			spy = sinon.spy(events.emitter,"emit")
			message = 
				message_id:"111111"
				protocol:"content"
				method:"RENAME"
				date:+new Date
				spl:place_id
				dpl:place_id
				content_id:content.id
				content_type:'file'
				data:
					relative_path:new_relative_path
				clear_data:
					new_content_id:new_id
				code:200
			framework.getService("communication_layer").inject message
			setTimeout ->
				events.emitter.emit.restore()
				expect(spy.withArgs("content:rename",place_id,content.id,new_id,new_relative_path).calledOnce).to.be.true
				done()
			,300
		it 'should call renameFileContent when sending a rename request from the Http interface',(done)->
			spy = sinon.spy(module,"renameFileContent")
			options =
				content_id:content.id
				new_relative_path:new_relative_path
			post_data = JSON.stringify options
			post_options =
				host:"localhost"
				port:8080
				path:"/core/api/place/content/rename/?place_name=#{place_id}"
				method:"POST"
				headers:
					"Content-Type":"application/json"
					"Content-Length":post_data.length
			fs.writeFileSync(new_path,fs.readFileSync(original_file_path))
			req = http.request post_options,(res)->
				res.setEncoding 'utf8'
				resp = ""
				res.on 'data',(chunk)->
					resp += chunk
				res.on 'end',->
					module.renameFileContent.restore()
					expect(spy.withArgs(place_id,sinon.match({old_content_id:content.id,new_relative_path:new_relative_path,emit_network:true})).calledOnce).to.be.true
					done()
			req.on 'error',(e)->
				throw e
				done()
			req.write(post_data)
			req.end()
		it 'should not emit event when request from Http interface',(done)->
			events = framework.getService("events")
			spy = sinon.spy(events.emitter,"emit")
			options =
				content_id:content.id
				new_relative_path:new_relative_path
			post_data = JSON.stringify options
			post_options =
				host:"localhost"
				port:8080
				path:"/core/api/place/content/rename/?place_name=#{place_id}"
				method:"POST"
				headers:
					"Content-Type":"application/json"
					"Content-Length":post_data.length
			fs.writeFileSync(new_path,fs.readFileSync(original_file_path))
			req = http.request post_options,(res)->
				res.setEncoding 'utf8'
				resp = ""
				res.on 'data',(chunk)->
					resp += chunk
				res.on 'end',->
					events.emitter.emit.restore()
					expect(spy.withArgs().calledOnce).not.to.be.true
					done()
			req.on 'error',(e)->
				throw e
				done()
			req.write(post_data)
			req.end()
		it 'should not change the database model if kernel return not 200 response',(done)->
			service = framework.getService("protocol.builder").content
			originalRename = service.renameRequest
			sendSpy = null
			message=
				method: 'RENAME',
				protocol: 'content',
				dpl: place_id
				spl: place_id
				code: 400,
				desc: 'ERROR'
			stub = sinon.stub service,"renameRequest",->
				obj = originalRename.apply null,arguments
				obj.send = (cb)->
					cb null,message
				return obj
			module.renameFileContent place_id,{old_content_id:content.id,new_relative_path:new_relative_path,content_type:'file',emit_network:true},(err)->
				module.getContentById place_id,new_id,{raw:false,unmarshall:false},(err,content)->
					expect(err).to.be.equal("Content not found")
					done()
