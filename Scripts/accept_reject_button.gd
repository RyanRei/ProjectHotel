class_name AcceptRejectButton
extends Control
signal choiceMade(choice:String)
var current_node:DialogueNode
var active:bool=false
var questionActive:bool=true
@export var accept:Button
@export var reject:Button

@export var question:Button
var previous_focus






# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.modulate=Color(1,1,1,0)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	pass # Replace with function body.
	
func _on_focus_changed(control):
	if control==accept or control==reject or control==question:
		if previous_focus:
			previous_focus.scale=Vector2.ONE
		control.scale=Vector2(1.5,1.5)
		previous_focus=control
	
	
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
	if  not active:
		return
	if event.is_action_pressed("Question"):
		
		if not questionActive:
			return
		question.grab_focus()
		
		
	if event.is_action_pressed("Accept"):
		
		accept.grab_focus()
		#choiceMade.emit("ACCEPT")
		pass
	elif event.is_action("Reject"):
		reject.grab_focus()
		
		pass
		
	if event.is_action_pressed("Confirm"):
		var focused_button = get_viewport().gui_get_focus_owner()
		if focused_button!=null:
			if focused_button==accept:
				choiceMade.emit("ACCEPT")
			elif focused_button==reject:
				choiceMade.emit("REJECT")
			elif focused_button==question:
				choiceMade.emit("QUESTION")
			get_viewport().set_input_as_handled()
				
				
				



	

func turnOff():
	active=false
	var tween=create_tween()
	tween.tween_property(self,"modulate:a",0.0,0.5)
	await tween.finished
	
	
func turnOn(question_node_visibility:bool):
	
	if question_node_visibility:
		$question.visible=true
		questionActive=true
	else:
		$question.visible=false
		questionActive=false
	var tween=create_tween()
	tween.tween_property(self,"modulate:a",1.0,0.5)
	await tween.finished
	active=true
	
	




	#await Signal.any(accept,reject)
	
#func _on_accept_pressed() -> void:
	#
	#choiceMade.emit("ACCEPT")
#
#
#
#func _on_reject_pressed() -> void:
	#choiceMade.emit("REJECT")
	#
#
#
#func _on_question_pressed() -> void:
	#choiceMade.emit("QUESTION")
