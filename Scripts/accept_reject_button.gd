class_name AcceptRejectButton
extends Control
signal choiceMade(choice:String)
var current_node:DialogueNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




	

func turnOff():
	var tween=create_tween()
	tween.tween_property(self,"modulate:a",0.0,0.5)
	await tween.finished
	
	
func turnOn(question_node_visibility:bool):
	if question_node_visibility:
		$question.visible=true
	else:
		$question.visible=false
	var tween=create_tween()
	tween.tween_property(self,"modulate:a",1.0,0.5)
	await tween.finished
	
	




	#await Signal.any(accept,reject)
	
func _on_accept_pressed() -> void:
	
	choiceMade.emit("ACCEPT")



func _on_reject_pressed() -> void:
	choiceMade.emit("REJECT")
	


func _on_question_pressed() -> void:
	choiceMade.emit("QUESTION")
