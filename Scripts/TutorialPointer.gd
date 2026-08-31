class_name TutorialPointer3D
extends Node3D

var target: Node3D


func _ready() -> void:
	# Environmental lighting now carries tutorial direction. Keep this node as a
	# compatibility shim for older tutorial calls, but never spawn a marker.
	target = null


func _process(delta: float) -> void:
	pass


func point_at(object: Node3D, vertical_offset := -1.0) -> void:
	# Intentionally visual-free: spotlights are the only world-space guide.
	target = null


func hide_pointer() -> void:
	target = null


func update_pointer_position() -> void:
	pass
