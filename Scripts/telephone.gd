class_name Phone
extends Area3D

var ringing := false
var answering := false
var answer_generation := 0
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
		return
	if answering or not DialogueManager.active:
		return
	var call_manager := get_tree().get_first_node_in_group("call_manager")
	if call_manager != null and call_manager.has_method("request_call_manager_toggle"):
		call_manager.call("request_call_manager_toggle")


func answer() -> void:
	if not ringing or answering:
		return
	answer_generation += 1
	var run_generation := answer_generation
	answering = true
	tele_phone.stop()
	tele_phone.stream = pickupSound
	tele_phone.play()
	ringing = false
	await get_tree().create_timer(1.0).timeout
	if run_generation != answer_generation:
		return
	answering = false
	call_answered.emit()


func skip_ringing() -> void:
	answer_generation += 1
	tele_phone.stop()
	ringing = false
	answering = false
	call_answered.emit()
