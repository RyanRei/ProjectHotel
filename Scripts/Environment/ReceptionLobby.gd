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
	_elevator_tween = create_tween().set_parallel(true)
	_elevator_tween.tween_property(elevator_left, "position:z", -13.2, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_elevator_tween.tween_property(elevator_right, "position:z", -2.8, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _elevator_tween.finished


func close_elevator() -> void:
	if not elevator_open:
		return
	elevator_open = false
	if _elevator_tween != null:
		_elevator_tween.kill()
	_elevator_tween = create_tween().set_parallel(true)
	_elevator_tween.tween_property(elevator_left, "position:z", -10.0, 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_elevator_tween.tween_property(elevator_right, "position:z", -6.0, 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _elevator_tween.finished
