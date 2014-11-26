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
jadeHelpers = require "../../common_lib/jadeHelpers"
utils = require "../../common_lib/utils"

_ = require 'underscore'
module.exports = (options,imports,register)->
	account_lib = imports["api.account"]
	protocol_builder = imports["protocol.builder"]
	com_layer = imports.communication_layer #INFO just to replay message and test protocols
	server = imports.server
	express_app = server.app
	stepManager = server.stepManager

	i18n = server.i18n

	stepManager.setSteps
		core_init:
			url:"/"
		account_check:
			url:"/check/"
		login:
			url:"/login/"
		languages:
			url:"/languages/"
			authorized_routes:["^\/languages\/.*\/$"]
		register:
			url:"/register/"
		conflict:
			url:"/conflict/"
		account_validation:
			url:"/account_validation/"
			authorized_routes:["^\/resend_code\/","^\/reset\/$"]
		main_app:
			url:"/app/"
	,{
		initial_step:"core_init"
		global_routes:["^\/step\/.*","\/favicon.ico","^\/images\/.*","^\/core\/api\/.*","^\/utils\/.*"]
		final_step:"main_app"
	}

	#http api to know if a step hasb been validated or not (long polling)
	express_app.get "/step/:name/validated/",(req,res)->
		stepManager.onAfterStepValidated req.param('name'),(nextUrl)->
			res.send {ok:true,url:nextUrl}

	express_app.get '/check/',(req,res)->
		res.render 'account_check'
		account_lib.getAccountStatus (err,status)->
			lang = account_lib.getUserLanguage()
			i18n.setLng lang, {fixLng: true }, (t) ->
				express_app.locals.t = t
				switch status
					when account_lib.STATUS.unverified
						stepManager.goToStep("account_validation",{validate_current:true})
					when account_lib.STATUS.verified
						stepManager.goToStep("login",{validate_current:true})
					when account_lib.STATUS.conflict
						stepManager.goToStep("conflict",{validate_current:true})
					else
						stepManager.goToStep("languages",{validate_current:true})

	express_app.get '/login/',(req,res)->
		if account_lib.isLogged()
			stepManager.goToStep('main_app',{res:res})
		else
			res.render 'login',jadeHelpers.getFormData(req,['email'])

	express_app.post '/login/',(req,res)->
		alias =
			alias:req.body.email
			type:"email"
		password = req.body.password
		jadeHelpers.buildFlashForm(req,{omit:['password']})
		account_lib.login alias,password,(err,authenticated)->
			if err?
				req.flash('err', {mesg:err})
				res.redirect '/login/'
			else
				if authenticated == true
					stepManager.goToStep('main_app',{res:res})
				else
					req.flash "err",{mesg:"Wrong email or password!"}
					stepManager.goToStep('login',{res:res})

	express_app.get '/languages/:lang/',(req,res)->
		lang = req.param('lang');
		if lang in ['fr_FR', 'en_US']
			account_lib.setUserLanguage(lang)
			i18n.setLng(lang, (t) ->
				express_app.locals.t = t
				stepManager.goToStep('register',{res:res})
			);
		else res.redirect '/languages/'

	express_app.get '/languages/',(req,res)->
		res.render 'languages'

	express_app.get '/register/',(req,res)->
		res.render 'register', jadeHelpers.getFormData(req,['firstname','lastname','email'])

	handleRegisterReply = (err,req,res)->
			if err == null
				stepManager.goToStep('account_validation',{res:res,validate_current:false})
			else if err.code == 449
				stepManager.goToStep('conflict',{res:res})
			else if err.code == 409
				stepManager.goToStep('check',{res:res})
			else
				req.flash('err', {code:err.code,mesg:err.message})
				stepManager.goToStep('register',{res:res})
				
	express_app.post '/register/',(req,res)->
		account_lib.register _.clone(req.sanitize(req.body)),{field_name:"email",type:"email"},(err,reply)->
			err = err.message || err if err?
			if utils.isPlacesTestSuite(req)
				res.send {err:err}
			else
				if err?
					req.flash 'err',{mesg:err}
					jadeHelpers.buildFlashForm(req,{omit:['password','password-confirm']})
					stepManager.goToStep("register",{res:res})
				else
					handleRegisterReply err,req,res	
						
	express_app.get '/redirect/',(req,res)->
		res.render 'redirect'

	express_app.get '/account_validation/',(req,res)->
		alias = account_lib.getFirstAlias()
		email = if alias?.alias then alias.alias else "you"
		res.render 'account_validation',{email:email}

	express_app.post '/resend_code/',(req,res)->
		clear_password = req.body.password
		account_lib.resend_code clear_password,(err,service_err,http_info)->
			res.send {err:err,service_err:service_err,http_info:http_info}

	express_app.get "/app/",(req,res)->
		stepManager.stepsFinished()
		res.render("application",{host:req.headers.host})

	express_app.get "/conflict",(req,res)->
		res.render 'conflict'

	express_app.post "/conflict",(req,res)->
		decision = req.body.decision
		if decision == "discard"
			account_lib.resetAccount (err,info)->
				if err?
					err = err.message || err
					req.flash "err",{mesg:err}
					stepManager.goToStep("conflict",{res:res})
				else
					stepManager.goToStep("register",{res:res})
		else
			account_lib.accountRegistrationRetry (err,account)->
				if err?
					err = err.message || err
					req.flash "err",{mesg:err}
					stepManager.goToStep("conflict",{res:res})
				else
					handleRegisterReply err,req,res


	express_app.get "/",(req,res)->
		res.render "index"

	express_app.get "/reset/",(req,res)->
		account_lib.resetAccount (err,info)->
			if err?
				err = err.message || err
				req.flash "err",{mesg:err}
				stepManager.goToStep("check",{res:res})
			else
				stepManager.goToStep("register",{res:res})

	express_app.post "/inject/",(req,res)->
		com_layer.inject(req.body)
		res.send "ok"

	express_app.get "/utils/ready/",(req,res)->
		if server.is_ready()
			res.send 200
		else
			res.send 503

	express_app.get "/conference/",(req,res)->
		res.render "conference"

	register null,{}