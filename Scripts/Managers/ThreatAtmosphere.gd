class_name ThreatAtmosphere
extends Node

@export var lights_root: Node
@export var telephone_threat_light: SpotLight3D
@export_range(0.0, 0.5, 0.01) var threat_energy_factor := 0.0
@export_range(0.1, 8.0, 0.1) var transition_seconds := 4.2

var threat_active := false


func _ready() -> void:
	if not DialogueManager.dialogue_started.is_connected(_on_dialogue_started):
		DialogueManager.dialogue_started.connect(_on_dialogue_started)


func _on_dialogue_started(dialogue: DialogueNode) -> void:
	if threat_active or dialogue == null or dialogue.voiceline == null:
		return
	var clip_path := dialogue.voiceline.resource_path.to_lower()
	if not clip_path.get_file().begins_with("devious"):
		return
	activate_threat_state()


func activate_threat_state() -> void:
	threat_active = true
	MusicManager.play_stress()
	var blackout_root := get_tree().current_scene if get_tree().current_scene != null else lights_root
	if blackout_root == null:
		return
	var lights: Array[Light3D] = []
	# Search the complete gameplay scene so lobby, tutorial, elevator, desk and
	# prop lights all go dark—not only the original local Lights container.
	_collect_lights(blackout_root, lights)
	var tween := create_tween().set_parallel(true)
	for light in lights:
		if light == telephone_threat_light:
			continue
		var dim_energy := light.light_energy * threat_energy_factor
		var threat_color := light.light_color.lerp(Color(0.52, 0.13, 0.055), 0.58)
		tween.tween_property(light, "light_energy", dim_energy, transition_seconds)
		tween.tween_property(light, "light_color", threat_color, transition_seconds)
	if telephone_threat_light:
		telephone_threat_light.visible = true
		telephone_threat_light.light_energy = 0.0
		tween.tween_property(telephone_threat_light, "light_energy", 7.5, transition_seconds)
	for monitor in get_tree().get_nodes_in_group("computer_monitor"):
		if monitor.has_method("activate_threat_flicker"):
			monitor.call("activate_threat_flicker")


func _collect_lights(node: Node, output: Array[Light3D]) -> void:
	if node is Light3D:
		output.append(node as Light3D)
	for child in node.get_children():
		_collect_lights(child, output)
