class_name ComputerMonitor
extends Node3D

const SCREEN_BACKGROUND := Color("10171a")
const SCREEN_PANEL := Color("182328")
const SCREEN_AMBER := Color("b17b32")
const SCREEN_TEXT := Color("ddd1b2")

var screen_mesh: MeshInstance3D
var click_area: Area3D
var idle_viewport: SubViewport
var scan_line: ColorRect
var activity_light: ColorRect
var roster_rows: Array[ColorRect] = []
var animation_time := 0.0
var active_row := 0


func _ready() -> void:
	set_process_unhandled_input(true)
	screen_mesh = find_screen_mesh(self)
	if screen_mesh == null:
		push_warning("ComputerMonitor could not find the imported computerScreen mesh.")
		return
	create_idle_display()
	create_click_area()
	set_process(true)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null or click_area == null:
		return
	var pointer_position: Vector2 = event.position
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pointer_position = get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(pointer_position)
	var destination := origin + camera.project_ray_normal(pointer_position) * 20.0
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.get("collider") == click_area:
		interact()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if idle_viewport == null:
		return
	animation_time += delta
	if scan_line != null:
		scan_line.position.y = 184.0 + fmod(animation_time * 72.0, 202.0)
	if activity_light != null:
		activity_light.color.a = 0.35 + (sin(animation_time * 3.5) + 1.0) * 0.3
	var next_row: int = int(animation_time / 1.6) % maxi(roster_rows.size(), 1)
	if next_row != active_row and not roster_rows.is_empty():
		roster_rows[active_row].color = SCREEN_PANEL
		active_row = next_row
		roster_rows[active_row].color = Color(SCREEN_AMBER, 0.82)


func find_screen_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		var mesh_name := node.get_parent().name.to_lower() + " " + node.name.to_lower()
		if "computerscreen" in mesh_name or "computer_low" in mesh_name:
			return node as MeshInstance3D
	for child in node.get_children():
		var result := find_screen_mesh(child)
		if result != null:
			return result
	return null


func create_idle_display() -> void:
	idle_viewport = SubViewport.new()
	idle_viewport.name = "RosterLiveViewport"
	idle_viewport.size = Vector2i(768, 480)
	idle_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	idle_viewport.transparent_bg = false
	add_child(idle_viewport)

	var background := ColorRect.new()
	background.color = SCREEN_BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	idle_viewport.add_child(background)

	var header := ColorRect.new()
	header.color = SCREEN_PANEL
	header.position = Vector2(22, 20)
	header.size = Vector2(724, 54)
	background.add_child(header)

	var system_name := make_screen_label("NIGHTHAVEN SHELTER SYSTEM", 21, SCREEN_TEXT)
	system_name.position = Vector2(18, 11)
	header.add_child(system_name)

	var clock := make_screen_label("11:45 PM", 18, SCREEN_TEXT)
	clock.position = Vector2(622, 13)
	header.add_child(clock)

	var tab_names := ["RESIDENTS", "VISITORS", "ROOMS", "ACCESS LOG"]
	for index in tab_names.size():
		var tab := ColorRect.new()
		tab.color = SCREEN_AMBER if index == 0 else SCREEN_PANEL
		tab.position = Vector2(22 + index * 181, 86)
		tab.size = Vector2(174, 42)
		background.add_child(tab)
		var tab_label := make_screen_label(tab_names[index], 15, SCREEN_TEXT)
		tab_label.position = Vector2(16, 10)
		tab.add_child(tab_label)

	var search := ColorRect.new()
	search.color = Color("0d1316")
	search.position = Vector2(22, 140)
	search.size = Vector2(724, 40)
	background.add_child(search)
	var search_text := make_screen_label("SEARCH NAME / ROOM / STATUS", 14, Color("8e9388"))
	search_text.position = Vector2(14, 10)
	search.add_child(search_text)

	var rows := [
		"ROOM 104    TRACEY MORGAN       OCCUPIED",
		"ROOM 207    ARTHUR WILLIAMS     OCCUPIED",
		"ROOM 312    MAYA BENNETT        AWAY",
		"ROOM 408    DANIEL KIM          OCCUPIED",
	]
	for index in rows.size():
		var row := ColorRect.new()
		row.color = Color(SCREEN_AMBER, 0.82) if index == 0 else SCREEN_PANEL
		row.position = Vector2(22, 194 + index * 48)
		row.size = Vector2(724, 40)
		background.add_child(row)
		roster_rows.append(row)
		var row_text := make_screen_label(rows[index], 15, SCREEN_TEXT)
		row_text.position = Vector2(14, 10)
		row.add_child(row_text)

	var instruction := make_screen_label("CLICK SCREEN TO OPEN ROSTER", 16, SCREEN_AMBER)
	instruction.position = Vector2(250, 403)
	background.add_child(instruction)
	var status := make_screen_label("SYSTEM ONLINE  •  RECORDS UPDATED 11:30 PM", 13, Color("879187"))
	status.position = Vector2(22, 448)
	background.add_child(status)

	activity_light = ColorRect.new()
	activity_light.color = SCREEN_AMBER
	activity_light.position = Vector2(726, 449)
	activity_light.size = Vector2(10, 10)
	background.add_child(activity_light)

	scan_line = ColorRect.new()
	scan_line.color = Color(0.82, 0.64, 0.34, 0.10)
	scan_line.position = Vector2(22, 184)
	scan_line.size = Vector2(724, 3)
	scan_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(scan_line)

	var quad := QuadMesh.new()
	var bounds := screen_mesh.get_aabb()
	# The imported monitor has no separate screen material. This inset quad sits
	# just behind the front bezel so it reads as the glass instead of an overlay.
	# Cover the downloaded model's complete baked Windows screen, leaving only
	# its physical black bezel visible.
	quad.size = Vector2(bounds.size.x * 0.86, bounds.size.y * 0.86)
	quad.orientation = PlaneMesh.FACE_Z

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = idle_viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission_texture = idle_viewport.get_texture()
	material.emission_energy_multiplier = 0.85
	quad.material = material

	var display := MeshInstance3D.new()
	display.name = "RosterIdleDisplay"
	display.mesh = quad
	display.position = Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.position.y + bounds.size.y * 0.50,
		bounds.end.z + 0.002
	)
	screen_mesh.add_child(display)

	# Emissive materials look bright but do not illuminate nearby geometry.
	# This restrained amber light supplies the subtle desk glow from the LCD.
	var screen_glow := OmniLight3D.new()
	screen_glow.name = "ScreenGlow"
	screen_glow.light_color = Color("d69b55")
	screen_glow.light_energy = 0.42
	screen_glow.omni_range = 2.4
	screen_glow.shadow_enabled = false
	screen_glow.position = display.position + Vector3(0, 0, 0.16)
	screen_mesh.add_child(screen_glow)


func create_click_area() -> void:
	var bounds := screen_mesh.get_aabb()
	click_area = Area3D.new()
	click_area.name = "RosterClickArea"
	click_area.add_to_group("interactable")
	click_area.set_meta("interaction_target", self)
	click_area.input_ray_pickable = true
	click_area.collision_layer = 1
	click_area.collision_mask = 1
	screen_mesh.add_child(click_area)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(bounds.size.x * 0.90, bounds.size.y * 0.90, 0.025)
	shape.shape = box
	shape.position = Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.position.y + bounds.size.y * 0.50,
		bounds.end.z + 0.008
	)
	click_area.add_child(shape)
	click_area.input_event.connect(_on_monitor_input_event)
	click_area.mouse_entered.connect(func() -> void: Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	click_area.mouse_exited.connect(func() -> void: Input.set_default_cursor_shape(Input.CURSOR_ARROW))


func _on_monitor_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_index: int
) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		interact()
		get_viewport().set_input_as_handled()


func interact() -> void:
	var roster := get_tree().get_first_node_in_group("roster_ui") as RosterUI
	if roster != null:
		roster.open_roster()


func make_screen_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
