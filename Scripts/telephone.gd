class_name Phone
extends Area3D

var ringing := false
var answering := false
signal call_answered
@export var ringSound: AudioStream
@export var pickupSound: AudioStream
@onready var tele_phone: AudioStreamPlayer3D = $RingAudio


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interaction_target", self)


func start_ringing() -> void:
	if not ringing:
		tele_phone.stream = ringSound
		tele_phone.play()
		ringing = true
		answering = false


func interact() -> void:
	if ringing and not answering:
		answer()


func answer() -> void:
	if not ringing or answering:
		return
	answering = true
	tele_phone.stop()
	tele_phone.stream = pickupSound
	tele_phone.play()
	ringing = false
	await get_tree().create_timer(1.0).timeout
	answering = false
	call_answered.emit()
