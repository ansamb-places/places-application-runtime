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
_ = require 'underscore'
_when = require 'when'
{EventEmitter} = require 'events'

module.exports = class StepValidator extends EventEmitter
	constructor:->
		@_currentStep = null
		@steps = []
		@disable = false
	setSteps:(steps,options)->
		###
		steps is an array of object with the following object structure
		{
			url:string (ex:'/'),
			authorized_routes:array (ex:['^\/login$']),
		}
		###
		@steps = []
		@default_url = options.default_url || "/"
		_.each steps,(step,name)=>
			@steps[name] = _.extend {
				authorized_routes:[]
				validated : _when.defer()
			},step
		@_currentStep = options.initial_step || Object.keys(@steps)[0]
		@_final_step = options.final_step || _.last(Object.keys(@steps))
		@global_routes = options.global_routes||[]
		@final_url = null
	goToStep:(stepName,options)->
		options ?= {}
		if @getStep(stepName)
			if options.validate_current == true
				@validateStep(@_currentStep,stepName)
			@_currentStep = stepName
			@getStep(@_currentStep).validated = _when.defer()
			options.res.redirect @getCurrentUrl() if options.res
			return true
		else
			return false
	getStep:(stepName)->
		return @steps[stepName] || null
	onAfterStepValidated:(stepName,cb)->
		cb ?= ->
		if @final_url
			return cb @final_url
		step = @getStep(stepName)
		if step?
			step.validated.promise.done cb
		else
			cb "/"
	validateStep:(stepName,nextStepName)->
		step = @getStep(stepName)
		nextStep = @getStep(nextStepName)
		console.log "validate current step:#{stepName} and go to step:#{nextStepName}"
		if step?
			step.validated.resolve(@final_url||nextStep?.url||"/")
	getCurrentStep:->
		return @steps[@_currentStep] || null
	getCurrentUrl:->
		return @steps[@_currentStep]?.url || null
	isUrlAllowed:(url)->
		return true if @_currentStep == null
		if url == @getCurrentStep()?.url
			return true
		else
			return _.filter(@getCurrentStep().authorized_routes,(regex)->
				return new RegExp(regex).test(url)
			).length>0 or _.filter(@global_routes,(regex)->
				return new RegExp(regex).test(url)
			).length>0
	disableFiltering:->
		@disable = true
	stepsFinished:->
		@disableFiltering()
		@final_url = @getStep(@_final_step).url
	routeFiltering:->
		(req,res,next)=>
			return next() if @disable
			console.log "URL->",req.originalUrl
			if @isUrlAllowed(req.originalUrl)
				next()
			else
				console.log "Redirect to "+@getCurrentUrl()
				res.redirect(@getCurrentUrl())
