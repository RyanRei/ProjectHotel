extends Node3D

## The source character ships with one animation reel. Expose the useful opening
## walk cycle and its first-frame standing pose under the names expected by the
## encounter movement code.
@export_range(0.25, 5.0, 0.05) var walk_clip_length := 2.0
@export_range(0.05, 1.0, 0.05) var idle_clip_length := 0.1


func _ready() -> void:
	var players := find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_warning("Business female character has no AnimationPlayer.")
		return

	var player := players[0] as AnimationPlayer
	var source_name := _find_source_animation(player)
	if source_name == StringName():
		push_warning("Business female character has no source animation reel.")
		return

	var source := player.get_animation(source_name)
	var library := _find_animation_library(player, source_name)
	if source == null or library == null:
		push_warning("Business female animation reel could not be prepared.")
		return

	_add_or_replace(library, &"Walk", _make_clip(source, walk_clip_length, true))
	_add_or_replace(library, &"Idle", _make_clip(source, idle_clip_length, true))


func _find_source_animation(player: AnimationPlayer) -> StringName:
	var fallback := StringName()
	for animation_name in player.get_animation_list():
		var normalized := String(animation_name).to_lower()
		if normalized == "reset" or normalized.ends_with("/reset"):
			continue
		if fallback == StringName():
			fallback = animation_name
		if "take" in normalized:
			return animation_name
	return fallback


func _find_animation_library(player: AnimationPlayer, animation_name: StringName) -> AnimationLibrary:
	var full_name := String(animation_name)
	for library_name in player.get_animation_library_list():
		var library := player.get_animation_library(library_name)
		if library == null:
			continue
		for local_name in library.get_animation_list():
			if local_name == animation_name or "%s/%s" % [library_name, local_name] == full_name:
				return library
	return player.get_animation_library(&"")


func _make_clip(source: Animation, clip_length: float, should_loop: bool) -> Animation:
	var clip := source.duplicate(true) as Animation
	clip.length = minf(clip_length, source.length)
	clip.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE

	for track_index in range(clip.get_track_count()):
		for key_index in range(clip.track_get_key_count(track_index) - 1, -1, -1):
			if clip.track_get_key_time(track_index, key_index) > clip.length:
				clip.track_remove_key(track_index, key_index)
	return clip


func _add_or_replace(library: AnimationLibrary, animation_name: StringName, animation: Animation) -> void:
	if library.has_animation(animation_name):
		library.remove_animation(animation_name)
	library.add_animation(animation_name, animation)
