class_name DeskCameraController
extends Camera3D

@export_range(10.0, 90.0, 1.0) var horizontal_limit_degrees := 60.0
@export_range(5.0, 45.0, 1.0) var look_up_limit_degrees := 20.0
@export_range(5.0, 45.0, 1.0) var look_down_limit_degrees := 25.0
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity := 0.12
@export_range(1.0, 30.0, 0.5) var smoothing_speed := 14.0

var base_rotation: Vector3
var target_yaw := 0.0
var target_pitch := 0.0


func _ready() -> void:
	base_rotation = rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw -= deg_to_rad(event.relative.x * mouse_sensitivity)
		target_pitch -= deg_to_rad(event.relative.y * mouse_sensitivity)
		target_yaw = clamp(
			target_yaw,
			-deg_to_rad(horizontal_limit_degrees),
			deg_to_rad(horizontal_limit_degrees)
		)
		target_pitch = clamp(
			target_pitch,
			-deg_to_rad(look_up_limit_degrees),
			deg_to_rad(look_down_limit_degrees)
		)
	elif event is InputEventKey \
		and event.pressed \
		and not event.echo \
		and event.keycode == KEY_ESCAPE \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton \
		and event.pressed \
		and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE \
		and get_tree().get_first_node_in_group("roster_ui") is RosterUI \
		and not (get_tree().get_first_node_in_group("roster_ui") as RosterUI).visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var target_rotation := Vector3(
		base_rotation.x + target_pitch,
		base_rotation.y + target_yaw,
		base_rotation.z
	)
	rotation = Vector3(
		lerp_angle(rotation.x, target_rotation.x, 1.0 - exp(-smoothing_speed * delta)),
		lerp_angle(rotation.y, target_rotation.y, 1.0 - exp(-smoothing_speed * delta)),
		base_rotation.z
	)
