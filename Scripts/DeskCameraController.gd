class_name DeskCameraController
extends Camera3D

@export_group("Look Settings")
@export var mouse_look_enabled := true
@export_range(10.0, 90.0, 1.0) var horizontal_limit_degrees := 40.0
@export_range(5.0, 45.0, 1.0) var look_up_limit_degrees := 40.0
@export_range(5.0, 45.0, 1.0) var look_down_limit_degrees := 20.0
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity := 0.12
@export_range(1.0, 30.0, 0.5) var smoothing_speed := 14.0

@export_group("Movement Settings")
@export var movement_enabled := true
@export_range(0.5, 5.0, 0.1) var move_speed := 2.0
@export_range(0.1, 5.0, 0.1) var horizontal_move_limit := 2.0
@export_range(0.1, 5.0, 0.1) var forward_move_limit := 0.5
@export_range(0.1, 5.0, 0.1) var backward_move_limit := 0.6
@export_range(1.0, 30.0, 0.5) var position_smoothing := 10.0
@export_range(5.0, 20.0, 0.5) var head_bob_frequency := 4.0
@export_range(0.01, 0.2, 0.01) var head_bob_amplitude := 0.1

var base_rotation: Vector3
var base_x_z: Vector2
var base_height: float

var target_yaw := 0.0
var target_pitch := 0.0

var target_xz_offset := Vector2.ZERO
var current_xz_offset := Vector2.ZERO
var head_bob_time := 0.0


func _ready() -> void:
	base_rotation = rotation
	base_x_z = Vector2(position.x, position.z)
	base_height = position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_look_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw -= deg_to_rad(event.relative.x * mouse_sensitivity)
		target_pitch -= deg_to_rad(event.relative.y * mouse_sensitivity)
		target_yaw = clamp(target_yaw, -deg_to_rad(horizontal_limit_degrees), deg_to_rad(horizontal_limit_degrees))
		target_pitch = clamp(target_pitch, -deg_to_rad(look_up_limit_degrees), deg_to_rad(look_down_limit_degrees))

	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
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

	var input_dir := Vector2.ZERO

	if movement_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_physical_key_pressed(KEY_W):
			input_dir.y += 1.0
		if Input.is_physical_key_pressed(KEY_S):
			input_dir.y -= 1.0
		if Input.is_physical_key_pressed(KEY_A):
			input_dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			input_dir.x += 1.0

		input_dir = input_dir.normalized()

	if input_dir.length() > 0:
		var forward = -transform.basis.z
		var right = transform.basis.x

		var flat_forward = Vector2(forward.x, forward.z).normalized()
		var flat_right = Vector2(right.x, right.z).normalized()

		var move_dir = (flat_forward * input_dir.y) + (flat_right * input_dir.x)
		target_xz_offset += move_dir * move_speed * delta

	target_xz_offset.x = clamp(
		target_xz_offset.x,
		-horizontal_move_limit,
		horizontal_move_limit
	)

	target_xz_offset.y = clamp(
		target_xz_offset.y,
		-forward_move_limit,
		backward_move_limit
	)

	current_xz_offset = current_xz_offset.lerp(
		target_xz_offset,
		1.0 - exp(-position_smoothing * delta)
	)

	var bob_offset := 0.0

	if input_dir.length() > 0:
		head_bob_time += delta * head_bob_frequency
	else:
		var current_bob_phase = fmod(head_bob_time, PI)

		if current_bob_phase > 0.1:
			head_bob_time += delta * head_bob_frequency
		else:
			head_bob_time = 0.0

	bob_offset = abs(sin(head_bob_time)) * head_bob_amplitude

	position.x = base_x_z.x + current_xz_offset.x
	position.z = base_x_z.y + current_xz_offset.y
	position.y = base_height + bob_offset
