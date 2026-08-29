class_name EncounterProceedButton
extends Control
signal startEncounter

@onready var button: Button = $Button
var active := false


func _ready() -> void:
	set_hidden_immediately()



func _on_button_pressed() -> void:
	if active:
		startEncounter.emit()


func _input(event: InputEvent) -> void:
	if active and event.is_action_pressed("Question"):
		startEncounter.emit()
		get_viewport().set_input_as_handled()


func set_hidden_immediately() -> void:
	active = false
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.disabled = true


func turnOff() -> void:
	active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.disabled = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished


func turnOnEndShift() -> void:
	active = true
	button.text = "[Q] End Shift"
	button.disabled = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	await tween.finished
