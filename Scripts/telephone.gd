class_name Phone
extends Area3D
var ringing:=false
signal call_answered
@export var ringSound:AudioStream
@export var pickupSound:AudioStream
@onready var tele_phone: AudioStreamPlayer3D = $RingAudio

func start_ringing():
	if not ringing:
		tele_phone.stream=ringSound
		tele_phone.play()
		ringing=true

func answer():
	if ringing:
		tele_phone.stop()
		tele_phone.stream=pickupSound
		tele_phone.play()
		ringing=false
		await get_tree().create_timer(1.0).timeout
		call_answered.emit()
		


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if ringing:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				answer()
