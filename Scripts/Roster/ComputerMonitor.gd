class_name ComputerMonitor
extends Node3D
signal computer_clicked
const SCREEN_BACKGROUND := Color("10171a")
const SCREEN_PANEL := Color("182328")
const SCREEN_AMBER := Color("b17b32")
const SCREEN_TEXT := Color("ddd1b2")
@export var clickable := true
var screen_mesh: MeshInstance3D
var click_area: Area3D
var idle_viewport: SubViewport
var scan_line: ColorRect
var activity_light: ColorRect
var roster_rows: Array[ColorRect] = []
var animation_time := 0.0
var active_row := 0
var display_mesh: MeshInstance3D
var display_material: StandardMaterial3D
var screen_glow: OmniLight3D
var threat_flicker_active := false
var flicker_time_remaining := 0.0
var flicker_rng := RandomNumberGenerator.new()
var blackout_overlay: ColorRect
var threat_screen_on := true
var threat_elapsed := 0.0
var threat_shutdown_active := false
var threat_shutdown_elapsed := 0.0
var threat_shutdown_duration := 4.0
var shutdown_fade_overlay: ColorRect


func _ready() -> void:
	add_to_group("computer_monitor")
	flicker_rng.randomize()
	screen_mesh = find_screen_mesh(self)
	if screen_mesh == null:
		push_warning("ComputerMonitor could not find the imported computerScreen mesh.")
		return
	create_idle_display()
	create_click_area()
	set_process(true)

func _process(delta: float) -> void:
	if idle_viewport == null:
		return
	if threat_flicker_active:
		_update_threat_flicker(delta)
	if threat_shutdown_active:
		_update_threat_shutdown(delta)
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

	var tab_names := ["ROOMS", "VISITORS", "RESIDENTS"]
	for index in tab_names.size():
		var tab := ColorRect.new()
		tab.color = SCREEN_AMBER if index == 0 else SCREEN_PANEL
		tab.position = Vector2(22 + index * 242, 86)
		tab.size = Vector2(234, 42)
		background.add_child(tab)
		var tab_label := make_screen_label(tab_names[index], 15, SCREEN_TEXT)
		tab_label.position = Vector2(16, 10)
		tab.add_child(tab_label)

	var search := ColorRect.new()
	search.color = Color("0d1316")
	search.position = Vector2(22, 140)
	search.size = Vector2(724, 40)
	background.add_child(search)
	var search_text := make_screen_label("SEARCH ROOM RECORDS", 14, Color("8e9388"))
	search_text.position = Vector2(14, 10)
	search.add_child(search_text)

	var rows := [
		"ROOM 102    VACANT",
		"ROOM 104    TRACEY MORGAN              OCCUPIED",
		"ROOM 112    ARTHUR / ANGELICA WILLIAMS OCCUPIED",
		"ROOM 203    ELENA VOSS                  OCCUPIED",
	] if GameState.day == 1 else [
		"ROOM 207    DANIEL REEVES / MICHAEL TURNER  OCCUPIED",
		"ROOM 410    ETHAN COLE / DIANA WEBB         OCCUPIED",
		"ROOM 412    ASSIGNMENT UPDATE                IN SYNC",
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

	# Keep the physical display surface present during a failure. A black panel
	# inside the live viewport prevents the imported model's baked desktop image
	# from showing through between roster flashes.
	blackout_overlay = ColorRect.new()
	blackout_overlay.name = "ThreatBlackout"
	blackout_overlay.color = Color.BLACK
	blackout_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackout_overlay.visible = false
	background.add_child(blackout_overlay)

	# This second black layer performs the final post-hang-up power-down. It is
	# independent from the hard flicker layer, allowing the LCD to keep glitching
	# underneath while the whole display gradually disappears into black.
	shutdown_fade_overlay = ColorRect.new()
	shutdown_fade_overlay.name = "ThreatShutdownFade"
	shutdown_fade_overlay.color = Color(0, 0, 0, 0)
	shutdown_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shutdown_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shutdown_fade_overlay.visible = false
	background.add_child(shutdown_fade_overlay)

	var quad := QuadMesh.new()
	var bounds := screen_mesh.get_aabb()
	# Fill the complete LCD opening rather than only the roster-window region.
	# The small remaining inset preserves the monitor's physical black bezel.
	# Because the blackout is drawn across the entire SubViewport, every visible
	# LCD pixel now turns black together during the threat flicker.
	quad.size = Vector2(bounds.size.x * 0.95, bounds.size.y * 0.95)
	quad.orientation = PlaneMesh.FACE_Z

	display_material = StandardMaterial3D.new()
	display_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	display_material.albedo_texture = idle_viewport.get_texture()
	display_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	display_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	display_material.emission_enabled = true
	display_material.emission_texture = idle_viewport.get_texture()
	display_material.emission_energy_multiplier = 0.85
	quad.material = display_material

	display_mesh = MeshInstance3D.new()
	display_mesh.name = "RosterIdleDisplay"
	display_mesh.mesh = quad
	display_mesh.position = Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.position.y + bounds.size.y * 0.50,
		bounds.end.z + 0.002
	)
	screen_mesh.add_child(display_mesh)

	# Emissive materials look bright but do not illuminate nearby geometry.
	# This restrained amber light supplies the subtle desk glow from the LCD.
	screen_glow = OmniLight3D.new()
	screen_glow.name = "ScreenGlow"
	screen_glow.light_color = Color("d69b55")
	screen_glow.light_energy = 0.42
	screen_glow.omni_range = 2.4
	screen_glow.shadow_enabled = false
	screen_glow.position = display_mesh.position + Vector3(0, 0, 0.16)
	screen_mesh.add_child(screen_glow)


func activate_threat_flicker() -> void:
	threat_flicker_active = true
	threat_shutdown_active = false
	threat_elapsed = 0.0
	threat_screen_on = true
	flicker_time_remaining = 0.0
	if shutdown_fade_overlay:
		shutdown_fade_overlay.visible = false
		shutdown_fade_overlay.color.a = 0.0


func _update_threat_flicker(delta: float) -> void:
	threat_elapsed += delta
	flicker_time_remaining -= delta
	if flicker_time_remaining > 0.0:
		return
	# The longer the threat call lasts, the less often the roster recovers and
	# the longer each blackout holds. It begins near the original 3–4 Hz flicker
	# and deteriorates toward an LCD that is mostly black.
	var deterioration := clampf(threat_elapsed / 14.0, 0.0, 1.0)
	var black_probability := lerpf(0.5, 0.88, deterioration)
	threat_screen_on = flicker_rng.randf() > black_probability
	var screen_on := threat_screen_on
	if display_mesh:
		display_mesh.visible = true
	if blackout_overlay:
		blackout_overlay.visible = not screen_on
	if display_material:
		display_material.emission_energy_multiplier = flicker_rng.randf_range(0.72, 1.05) if screen_on else 0.0
	if screen_glow:
		# The LCD pixels remain visible, but during the threat blackout the monitor
		# must not cast another room light alongside the telephone spotlight.
		screen_glow.visible = false
		screen_glow.light_energy = 0.0
	if screen_on:
		flicker_time_remaining = flicker_rng.randf_range(
			lerpf(0.12, 0.045, deterioration),
			lerpf(0.17, 0.09, deterioration)
		)
	else:
		flicker_time_remaining = flicker_rng.randf_range(
			lerpf(0.12, 0.24, deterioration),
			lerpf(0.17, 0.62, deterioration)
		)


func begin_threat_shutdown(duration := 4.0) -> void:
	if not threat_flicker_active and not threat_shutdown_active:
		return
	threat_shutdown_active = true
	threat_shutdown_elapsed = 0.0
	threat_shutdown_duration = clampf(duration, 3.0, 5.0)
	if shutdown_fade_overlay:
		shutdown_fade_overlay.visible = true
		shutdown_fade_overlay.color = Color(0, 0, 0, 0)


func _update_threat_shutdown(delta: float) -> void:
	threat_shutdown_elapsed += delta
	var progress := clampf(threat_shutdown_elapsed / threat_shutdown_duration, 0.0, 1.0)
	# Slow start, then a heavier fall into darkness during the final seconds.
	var darkness := smoothstep(0.0, 1.0, progress)
	if shutdown_fade_overlay:
		shutdown_fade_overlay.color.a = darkness
	if display_material:
		display_material.emission_energy_multiplier *= 1.0 - delta * lerpf(0.15, 1.2, progress)
	if progress < 1.0:
		return
	threat_shutdown_active = false
	threat_flicker_active = false
	if blackout_overlay:
		blackout_overlay.visible = true
	if shutdown_fade_overlay:
		shutdown_fade_overlay.visible = true
		shutdown_fade_overlay.color = Color.BLACK
	if display_material:
		display_material.emission_energy_multiplier = 0.0


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
	click_area.mouse_entered.connect(func() -> void: Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	click_area.mouse_exited.connect(func() -> void: Input.set_default_cursor_shape(Input.CURSOR_ARROW))


func interact() -> void:
	if not clickable:
		return
	computer_clicked.emit()
	var roster := get_tree().get_first_node_in_group("roster_ui") as RosterUI
	if roster != null:
		roster.open_roster()
		


func make_screen_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
