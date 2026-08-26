class_name EncounterManager
extends Node
var encounterOngoing:=false
@export var phone:Phone
@export var encounter_button:EncounterProceedButton
func _ready() -> void:
	#start_encounter()
	encounter_button.startEncounter.connect(start_encounter)
	

@export var days: Array[Day]
#@export var visitor_container: Node3D
func get_current_encounter() -> EncounterData:
	return days[GameState.day - 1].encounters[GameState.encounter - 1]
	
	
	
	
func has_encounter() -> bool:
	while GameState.day <= days.size():
		var day = days[GameState.day - 1]
		print(day.encounters.size())
		print("heree")
		if GameState.encounter <= day.encounters.size():
			print("heree2")
			return true

		if GameState.day == days.size():
			print("heree3")
			return false

		GameState.day += 1
		GameState.encounter = 1
	print("heree4")
	return false
	

func start_encounter():
	if encounterOngoing:
		return
	if not has_encounter():
		return
		
	await encounter_startup_props()
	
	encounterOngoing=true
	
	var encounter = get_current_encounter()
	if encounter.communication_type=="CALL":
		await wait_for_phone()
	elif encounter.communication_type=="ONSITE":
		await move_customer(encounter.model)
		pass
		
	DialogueManager.start_dialogue(encounter.dialogue)
	await DialogueManager.dialogue_finished
	
	await encounter_end_props()
	
	GameState.encounter += 1
	encounterOngoing=false
	

func move_customer(model:PackedScene):
	var person:Node3D=model.instantiate()
	get_tree().current_scene.add_child(person)
	person.position=Vector3(-22.2,0,-6.22)
	var tween = create_tween()
	tween.tween_property(person, "position", Vector3(-3.249, -1.55, -3.682), 2.0)
	await tween.finished
	
func wait_for_phone():
	phone.start_ringing()
	await phone.call_answered 



#to control whatever we wanna do at start of encounter
func encounter_startup_props():
	await encounter_button.turnOff()
	pass


func encounter_end_props():
	await encounter_button.turnOn()
	pass
