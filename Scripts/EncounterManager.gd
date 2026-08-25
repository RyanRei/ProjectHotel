class_name EncounterManager
extends Node

@export var phone:Phone

func _input(event: InputEvent) -> void:
	print("hi")
	if event.is_action_pressed("Pickup Call"):
		start_encounter()


@export var days: Array[Day]
#@export var visitor_container: Node3D
func get_current_encounter() -> EncounterData:
	return days[GameState.day - 1].encounters[GameState.shift - 1]
	
func start_encounter():
	var encounter = get_current_encounter()
	if encounter.communication_type=="CALL":
		await wait_for_phone()
	#var visitor = encounter.visitor_scene.instantiate()
	#visitor_container.add_child(visitor)
	print("check1")
	DialogueManager.start_dialogue(encounter.dialogue)
	
	
func wait_for_phone():
	phone.start_ringing()
	await phone.call_answered
