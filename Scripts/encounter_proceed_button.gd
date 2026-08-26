class_name EncounterProceedButton
extends Control
signal startEncounter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_button_pressed() -> void:
	startEncounter.emit()
	

func turnOff():
	var tween=create_tween()
	tween.tween_property(self,"modulate:a",0.0,1)
	await tween.finished
	
	
func turnOn():
	var tween=create_tween()
	tween.tween_property(self,"modulate:a",1.0,1)
	await tween.finished
