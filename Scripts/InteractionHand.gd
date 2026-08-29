class_name InteractionHand
extends Control

const HAND_IDLE := Color(0.86, 0.82, 0.70, 0.72)
const HAND_ACTIVE := Color(0.96, 0.67, 0.25, 1.0)
const OUTLINE := Color(0.08, 0.07, 0.055, 0.95)

@export var interaction_distance := 12.0

var is_hovering := false
var is_pressed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	resized.connect(queue_redraw)
	queue_redraw()


func _process(_delta: float) -> void:
	var was_hovering := is_hovering
	is_hovering = GameState.desk_state and find_interactable() != null
	visible = GameState.desk_state and not is_desk_ui_open()
	if was_hovering != is_hovering:
		queue_redraw()
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = event.pressed
		queue_redraw()
		# An open desk interface owns the mouse. Never ray-cast through it into
		# the monitor, telephone, or logbook sitting in the 3D scene behind it.
		if not GameState.desk_state or is_desk_ui_open():
			return
		if event.pressed:
			var pointer_position := get_pointer_position(event.position)
			var collider := find_interactable_at(pointer_position)
			if collider != null and collider.has_meta("interaction_target"):
				var target := collider.get_meta("interaction_target") as Node
				if target != null and target.has_method("interact"):
					target.call("interact")
					get_viewport().set_input_as_handled()


func find_interactable() -> CollisionObject3D:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	return find_interactable_at(get_pointer_position(get_viewport().get_mouse_position()))


func find_interactable_at(pointer_position: Vector2) -> CollisionObject3D:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var origin := camera.project_ray_origin(pointer_position)
	var destination := origin + camera.project_ray_normal(pointer_position) * interaction_distance
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	# Thin desk props can sit directly on another collision surface. Continue
	# through non-interactive hits so the visible prop remains selectable.
	for _attempt in 8:
		var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return null
		var collider := hit.get("collider") as CollisionObject3D
		if collider != null and collider.is_in_group("interactable"):
			return collider
		if collider == null:
			return null
		query.exclude.append(collider.get_rid())
	return null


func get_pointer_position(mouse_position: Vector2) -> Vector2:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return get_viewport_rect().size * 0.5
	return mouse_position


func is_desk_ui_open() -> bool:
	for node in get_tree().get_nodes_in_group("desk_ui"):
		if node is CanvasItem and (node as CanvasItem).visible:
			return true
	return false


func _draw() -> void:
	var center := size * 0.5
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		center = get_viewport().get_mouse_position()
	center += Vector2(0, 2 if is_pressed else 0)
	var color := HAND_ACTIVE if is_hovering else HAND_IDLE
	# Compact, low-resolution pointing-hand silhouette for the captured mouse.
	var hand := PackedVector2Array([
		Vector2(-3, 12), Vector2(-3, -9), Vector2(0, -13), Vector2(3, -9),
		Vector2(3, 1), Vector2(5, -2), Vector2(8, -1), Vector2(9, 2),
		Vector2(11, 0), Vector2(14, 1), Vector2(15, 5), Vector2(15, 12),
		Vector2(10, 18), Vector2(0, 18),
	])
	for index in hand.size():
		hand[index] += center
	draw_colored_polygon(hand, color)
	draw_polyline(hand + PackedVector2Array([hand[0]]), OUTLINE, 2.0, true)
	if is_hovering:
		draw_arc(center + Vector2(1, -10), 8.0, PI, TAU, 12, HAND_ACTIVE, 1.5, true)
		var prompt_position := center + Vector2(22, 12)
		draw_string(
			ThemeDB.fallback_font,
			prompt_position,
			"CLICK",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			HAND_ACTIVE
		)
