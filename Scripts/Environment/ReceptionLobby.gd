class_name ReceptionLobby
extends Node3D

@onready var entrance_left: Node3D = %EntranceDoorLeft
@onready var entrance_right: Node3D = %EntranceDoorRight
@onready var elevator_left: MeshInstance3D = %ElevatorDoorLeft
@onready var elevator_right: MeshInstance3D = %ElevatorDoorRight

var entrance_open := false
var elevator_open := false
var _entrance_tween: Tween
var _elevator_tween: Tween
var _elevator_open_sound: AudioStreamPlayer
var _elevator_close_sound: AudioStreamPlayer


func _ready() -> void:
	add_to_group("reception_lobby")


func open_entrance() -> void:
	if entrance_open:
		return
	entrance_open = true
	if _entrance_tween != null:
		_entrance_tween.kill()
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.tween_property(entrance_left, "position:x", -6.35, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_entrance_tween.tween_property(entrance_right, "position:x", 6.35, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _entrance_tween.finished


func close_entrance() -> void:
	if not entrance_open:
		return
	entrance_open = false
	if _entrance_tween != null:
		_entrance_tween.kill()
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.tween_property(entrance_left, "position:x", -3.45, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_entrance_tween.tween_property(entrance_right, "position:x", 3.45, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _entrance_tween.finished


func open_elevator() -> void:
	if elevator_open:
		return
	elevator_open = true
	if _elevator_tween != null:
		_elevator_tween.kill()
	_play_elevator_open_sound()
	# Delay before door starts opening (non-blocking)
	get_tree().create_timer(0.8).timeout.connect(_start_elevator_open_animation)


func close_elevator() -> void:
	if not elevator_open:
		return
	elevator_open = false
	if _elevator_tween != null:
		_elevator_tween.kill()
	await _play_elevator_close_sound()
	# Delay before door starts closing (non-blocking)
	get_tree().create_timer(0.3).timeout.connect(_start_elevator_close_animation)


func _play_elevator_open_sound() -> void:
	# Play elevator door opening sound
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.bus = &"Master"
	# Load your elevator open sound here
	player.stream = load("res://Assets/Sound/sfx/doorOpening.mp3")
	if player.stream != null:
		player.play()
		await player.finished
	player.queue_free()


func _play_elevator_close_sound() -> void:
	# Play elevator door closing sound
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.bus = &"Master"
	# Load your elevator close sound here
	player.stream = load("res://Assets/Sound/sfx/doorClosing.mp3")
	if player.stream != null:
		player.play()
		await player.finished
	player.queue_free()


func _start_elevator_open_animation() -> void:
	if _elevator_tween != null:
		_elevator_tween.kill()
	_elevator_tween = create_tween().set_parallel(true)
	_elevator_tween.tween_property(elevator_left, "position:z", -13.2, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_elevator_tween.tween_property(elevator_right, "position:z", -2.8, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _start_elevator_close_animation() -> void:
	if _elevator_tween != null:
		_elevator_tween.kill()
	_elevator_tween = create_tween().set_parallel(true)
	_elevator_tween.tween_property(elevator_left, "position:z", -10.0, 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_elevator_tween.tween_property(elevator_right, "position:z", -6.0, 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
