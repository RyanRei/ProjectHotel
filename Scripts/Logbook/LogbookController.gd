@tool
class_name LogbookController
extends Node3D
@export var logbook:LogbookUI
@export var logUpdateAudio:AudioStreamPlayer3D
@export var pageFlipAudio:AudioStreamPlayer3D
@export var isLogbookClikable:bool=true
signal logbook_clicked
var click_area: Area3D
var clickable_center := Vector3.ZERO
var clickable_size := Vector3.ZERO
var animation_player: AnimationPlayer
var page_animation := "Demo"
var animation_busy := false
var book_bounds := AABB()
var turning_page_mesh: MeshInstance3D
var page_material: StandardMaterial3D
var turn_direction := 1.0
var released_schedule_entries: Dictionary = {}
const PAGE_WIDTH_SEGMENTS := 24
const PAGE_LENGTH_SEGMENTS := 6
# The animated GLB reports a very large skinned AABB (roughly the whole desk).
# Use a deliberate hitbox around the visible closed book instead.
const CLICKABLE_CENTER := Vector3(0.0, 0.08, 0.0)
const CLICKABLE_SIZE := Vector3(0.28, 1.9, 2.4)
signal page_turn_midpoint
signal page_turn_finished

func _ready() -> void:
	apply_compact_editor_bounds()
	if Engine.is_editor_hint():
		return
	add_to_group("logbook_controller")
	if not TimeManager.time_updated.is_connected(_on_time_updated):
		TimeManager.time_updated.connect(_on_time_updated)
	_sync_scheduled_entries.call_deferred()
	animation_player = find_animation_player(self)
	click_area = Area3D.new()
	click_area.name = "LogbookClickArea"
	click_area.add_to_group("interactable")
	click_area.set_meta("interaction_target", self)
	click_area.input_ray_pickable = true
	click_area.collision_layer = 1
	add_child(click_area)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var bounds := calculate_mesh_bounds()
	book_bounds = bounds
	clickable_center = CLICKABLE_CENTER
	clickable_size = CLICKABLE_SIZE
	box.size = clickable_size
	collision.shape = box
	collision.position = clickable_center
	click_area.add_child(collision)
	if animation_player != null and animation_player.has_animation(page_animation):
		var animation: Animation = animation_player.get_animation(page_animation)
		animation_player.play(page_animation)
		animation_player.seek(animation.length, true)
		animation_player.pause()
	create_turning_page()

func apply_compact_editor_bounds() -> void:
	var book_mesh := find_book_mesh(self)
	if book_mesh == null:
		return
	# The skinned GLB ships with an invalid animation AABB spanning most of the
	# desk. Convert a compact root-local book box into the mesh's local space so
	# Godot's editor selection outline stays around the visible prop.
	var desired := AABB(Vector3(-0.45, -1.5, -2.0), Vector3(0.9, 3.0, 4.0))
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for x in [desired.position.x, desired.end.x]:
		for y in [desired.position.y, desired.end.y]:
			for z in [desired.position.z, desired.end.z]:
				var mesh_corner := book_mesh.to_local(to_global(Vector3(x, y, z)))
				minimum = minimum.min(mesh_corner)
				maximum = maximum.max(mesh_corner)
	book_mesh.custom_aabb = AABB(minimum, maximum - minimum)

func find_book_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == "Book_0":
		return node as MeshInstance3D
	for child in node.get_children():
		var result := find_book_mesh(child)
		if result != null:
			return result
	return null

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := find_animation_player(child)
		if result != null:
			return result
	return null

func play_page_turn(forward := true) -> void:
	if animation_busy:
		return
	animation_busy = true
	turn_direction = 1.0 if forward else -1.0
	turning_page_mesh.visible = true
	update_page_turn(0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(update_page_turn, 0.0, 0.5, 0.55)
	tween.tween_callback(page_turn_midpoint.emit)
	tween.tween_method(update_page_turn, 0.5, 1.0, 0.55)
	tween.tween_callback(finish_physical_page_turn)

func create_turning_page() -> void:
	turning_page_mesh = MeshInstance3D.new()
	turning_page_mesh.name = "PhysicalTurningPage"
	turning_page_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	page_material = StandardMaterial3D.new()
	page_material.albedo_color = Color("dfd0ab")
	page_material.roughness = 0.92
	page_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	turning_page_mesh.material_override = page_material
	add_child(turning_page_mesh)
	update_page_turn(0.0)
	turning_page_mesh.visible = false

func update_page_turn(progress: float) -> void:
	if turning_page_mesh == null:
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var spine_y := book_bounds.position.y + book_bounds.size.y * 0.5
	var half_width := book_bounds.size.y * 0.47
	var page_start_z := book_bounds.position.z + book_bounds.size.z * 0.035
	var page_length := book_bounds.size.z * 0.93
	# The imported book's local -X axis points upward from the desk.
	var surface_x := book_bounds.position.x - maxf(book_bounds.size.x * 0.025, 0.025)
	var angle := PI * progress
	for length_index in range(PAGE_LENGTH_SEGMENTS + 1):
		var v := float(length_index) / float(PAGE_LENGTH_SEGMENTS)
		for width_index in range(PAGE_WIDTH_SEGMENTS + 1):
			var u := float(width_index) / float(PAGE_WIDTH_SEGMENTS)
			var distance_from_spine := u * half_width
			var curl := sin(PI * u) * sin(PI * progress) * half_width * 0.22
			var edge_lift := sin(angle) * distance_from_spine * 0.42
			var x := surface_x - edge_lift - curl
			var y := spine_y + turn_direction * cos(angle) * distance_from_spine
			var z := page_start_z + v * page_length
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(-1.0, 0.0, 0.0))
			uvs.append(Vector2(u, v))
	for length_index in range(PAGE_LENGTH_SEGMENTS):
		for width_index in range(PAGE_WIDTH_SEGMENTS):
			var row_size := PAGE_WIDTH_SEGMENTS + 1
			var a := length_index * row_size + width_index
			var b := a + 1
			var c := a + row_size
			var d := c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var page_mesh := ArrayMesh.new()
	page_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	turning_page_mesh.mesh = page_mesh

func finish_physical_page_turn() -> void:
	turning_page_mesh.visible = false
	animation_busy = false
	page_turn_finished.emit()

func calculate_mesh_bounds() -> AABB:
	var mesh_nodes: Array[MeshInstance3D] = []
	collect_meshes(self, mesh_nodes)
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for mesh_node in mesh_nodes:
		var mesh_bounds := mesh_node.get_aabb()
		for x in [mesh_bounds.position.x, mesh_bounds.end.x]:
			for y in [mesh_bounds.position.y, mesh_bounds.end.y]:
				for z in [mesh_bounds.position.z, mesh_bounds.end.z]:
					var local_corner := to_local(mesh_node.to_global(Vector3(x, y, z)))
					minimum = minimum.min(local_corner)
					maximum = maximum.max(local_corner)
	if mesh_nodes.is_empty():
		return AABB(Vector3(-0.005, -0.004, -0.001), Vector3(0.01, 0.008, 0.002))
	return AABB(minimum, maximum - minimum)

func collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			output.append(child as MeshInstance3D)
		collect_meshes(child, output)

func interact() -> void:
	if not isLogbookClikable:
		return
	var ui := get_tree().get_first_node_in_group("logbook_ui")
	if ui != null and ui.has_method("open_logbook"):
		ui.call("open_logbook")
		logbook_clicked.emit()
		
		
func updateLogbook(encounter:EncounterData) -> void:
	if not logbook:
		push_warning("LogbookController has no LogbookUI assigned; entry was not recorded.")
		return
	if GameState.day == 1:
		_sync_scheduled_entries()
		return
	var index := GameState.day - 1
	logbook.append_log_entry(index, [
		encounter.time,
		encounter.name,
		encounter.room_number,
		encounter.logbook_type,
	], encounter.LogbookEntry)
	if logUpdateAudio:
		logUpdateAudio.play()


func _on_time_updated(_hour: int, _minute: int) -> void:
	_sync_scheduled_entries()


func _sync_scheduled_entries() -> void:
	if Engine.is_editor_hint() or GameState.day not in [1, 2] or not logbook:
		return
	var added_any := false
	var schedule := Shift1Data.logbook_schedule() if GameState.day == 1 else Shift2Data.logbook_schedule()
	for index in schedule.size():
		if released_schedule_entries.has(index):
			continue
		var item: Dictionary = schedule[index]
		var release_time := TimeManager.get_total_seconds_for(int(item.hour), int(item.minute))
		if TimeManager.in_game_seconds < release_time:
			continue
		logbook.append_log_entry(0, item.row, str(item.note))
		released_schedule_entries[index] = true
		added_any = true
	if added_any and logUpdateAudio:
		logUpdateAudio.play()
		
		
func add_page():
	released_schedule_entries.clear()
	var index=GameState.day-1
	logbook.pages.append({
		"tab":"LOGBOOK",
		"title":"LOGBOOK",
		"subtitle":"Day %d"%GameState.day,

		"columns":["TIME", "NAME", "ROOM", "TYPE"],
		"rows":[
		],
		"notes":""
		})
	logbook.show_page(GameState.day-1)
	pageFlipAudio.play()
		
		
