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
define [],()->
	_droppables = []

	#Return the stored droppable from the Jquery object obtained in the event target
	getDroppable=(element)->
		for el in _droppables
			if el.el.attr('class') == element.attr('class')
				return el
		return null
	
	# If a droppable is removed from the DOM (closing chat box or changing place)
	# you need to remove them from this list or unexpected behavior may appear
	# (Error "Tried to called droppable function prior to initialization" are due
	# to this )
	checkStoredDroppablesValidity=()->
		for el in _droppables by -1
			if not el.el.data("ui-droppable")
				index = _droppables.indexOf el
				_droppables.splice index, 1 if index != -1

	# We need to separate these function instead of implementing them in the
	# registerNewDroppable function due to Jquery behavior on droppables. When we manually 
	# trigger the functions linked to "drop", "out" and "over" of the droppable, the according
	# events are not fired up ("dropover", "dropout" and "drop"), so you have to call our custom
	# functions (if needed) each time you mannually trigger the droppable's "out", "drop" and "over"
	customOver=(event, ui)->
		current_droppable = getDroppable($(event.currentTarget))
		current_droppable.el.data("event", event)
		if !ui.helper.data("mutex")? || ui.helper.data("mutex") == "off"
			ui.helper.data("mutex", "on")
			ui.helper.data("priority", current_droppable.priority)
			ui.helper.data("currentDroppable", current_droppable.el)
			ui.helper.data("queue", [])
		else
			if ui.helper.data("priority") > current_droppable.priority
				ui.helper.data("currentDroppable").droppable("option", "out")(event, ui)
				ui.helper.data("currentDroppable").droppable("option", "disabled", true)
				ui.helper.data("priority", current_droppable.priority)
				ui.helper.data("queue").push ui.helper.data("currentDroppable")
				ui.helper.data("currentDroppable", current_droppable.el)
			else if ui.helper.data("priority") < current_droppable.priority
				ui.helper.data("queue").push current_droppable.el
				setTimeout -> 
					current_droppable.el.droppable("option", "out")(event, ui)
				, 0
				current_droppable.el.droppable("option", "disabled", true)

	customDrop=(event, ui)->
		if ui? && ui.helper?
			if ui.helper.data("queue")?
				for el in ui.helper.data("queue")
					el.droppable("option", "disabled", false)
					el.droppable("option", 'out')(event, ui)

	customOut=(event, ui)->
		checkStoredDroppablesValidity()
		ui.helper.data("mutex", "off")
		queue = ui.helper.data("queue")
		if queue? && queue.length > 0
			for el in queue
				el.droppable("option", "disabled", false)
				el.droppable("option", "over")(el.data("event"),  ui)
				customOver(el.data("event"), ui)
			ui.helper.data("queue", [])
		else
			ui.helper.data("mutex", "off")

	return{
		registerNewDroppable:(droppable, priority)->
			droppable.on "dropover", (event, ui)->
				customOver(event, ui)
			droppable.on "dropout", (event, ui)->
				customOut(event, ui)
			droppable.on "drop", (event, ui)->
				customDrop(event, ui)
			element_to_add = {el:droppable, priority:priority, over:false, disabled:false}
			_droppables.push element_to_add

			# Then, check if the droppable has not been registered already, otherwise, it may cause errors
			# Especially with chatboxes when you close the conversation and then open it again. Doing this
			# makes the DragAndDropManager to store the same element twice, but in different states, which
			# breaks the entire interaction
			checkStoredDroppablesValidity()
	}
