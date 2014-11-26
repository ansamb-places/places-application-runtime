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
define [
	'jquery.bpopup'
],(Bpopup)->
	Backbone.Marionette.Region.Dialog = Backbone.Marionette.Region.extend
		onShow:(view)->
			modal = @$el
			modal.removeClass()
			if @options.borderClass
				modal.addClass(@options.borderClass)
			if @options.closeButton
				modal.append("<span class='dialog-button p-default-button p-close'> ok </span>")
				close_button = $(modal.find('.p-close'))
				close_button.off 'click'
				close_button.on 'click', (e)->
					modal.bPopup().close()
			modal.bPopup({
				fadeSpeed: "fast",
				modal: true,
				escClose: true,
				onClose:=>
					view.close()
					@$el.removeClass()
					@options = {}
			})
			view.on 'close',=>
				modal.bPopup().close()
		setStyleOptions:(options)->
			@options = options
			@
		
	return Backbone.Marionette.Region.Dialog
