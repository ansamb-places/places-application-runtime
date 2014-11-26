class window.Promise
	constructor:(context)->
        @context = context || @
        @callbacks = []
        @resolved = undefined
    then:(callback)->
        if @resolved != undefined
            callback.apply(@context, @resolved)
        else
            @callbacks.push(callback)
    resolve:->
        return if @resolved 
        @resolved = arguments
        _.each @callbacks,(callback)=>
            callback.apply @context,@resolved