class_name TutorialPointer3D
extends Node3D

@export var hand_model: PackedScene
@export var hover_height := 0.4
@export var animation_speed := 2.0
@export var hover_amount := 0.1

var target: Node3D
var hand_instance: Node3D
var animation_time := 0.0
var rotating_target: Node3D
var active_hover_height := 0.4


func _ready() -> void:
	if hand_model:
		hand_instance = hand_model.instantiate()
		add_child(hand_instance)
		hand_instance.visible = false
		rotating_target = hand_instance.get_node_or_null("RotatingTarget") as Node3D


func _process(delta: float) -> void:
	if not target:
		return

	update_pointer_position()
	animation_time += delta * animation_speed
	if hand_instance:
		var pulse := 1.0 + sin(animation_time * 1.8) * 0.08
		hand_instance.scale = Vector3.ONE * pulse
	if rotating_target:
		rotating_target.rotation.y = animation_time * 0.7


func point_at(object: Node3D, vertical_offset := -1.0) -> void:
	target = object
	animation_time = 0.0
	active_hover_height = hover_height if vertical_offset < 0.0 else vertical_offset

	update_pointer_position()

	if hand_instance:
		hand_instance.visible = true


func hide_pointer() -> void:
	target = null

	if hand_instance:
		hand_instance.visible = false


func update_pointer_position() -> void:
	if not target:
		return

	global_position = target.global_position + Vector3.UP * active_hover_height
	global_position.y += sin(animation_time) * hover_amount
