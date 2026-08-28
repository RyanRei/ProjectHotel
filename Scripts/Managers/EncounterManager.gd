class_name EncounterManager
extends Node
@export var logBookController:LogbookController
var encounterOngoing:=false
@export var phone:Phone
@export var encounter_button:EncounterProceedButton
var day_results: Array[Dictionary] = []
@export var days: Array[Day]
@export var day_report_ui: DayReportUI
@export var guestModel:Node3D
enum MovePosition {
	MOVE_IN,
	MOVE_OUT
}

func _ready() -> void:
	#start_encounter()
	encounter_button.startEncounter.connect(start_encounter)
	


#@export var visitor_container: Node3D
func get_current_encounter() -> EncounterData:
	return days[GameState.day - 1].encounters[GameState.encounter - 1]
	
	
	
	

	

func start_encounter():
	if encounterOngoing:
		return
	if not has_encounter():
		return
		
	
	
	#await encounter_startup_props()
	#encounterOngoing=true
	
	var encounter = get_current_encounter()
	
	await encounter_startup_props(encounter)
	encounterOngoing=true
	
	if encounter.communication_type=="RESIDENT":
		await wait_for_phone()
	elif encounter.communication_type=="VISITOR":
		await move_customer(encounter.model,MovePosition.MOVE_IN)
		pass
	elif encounter.communication_type=="INFORMATIVE":
		await wait_for_phone()
		
		logBookController.updateLogbook(encounter)
		await encounter_button.turnOn()
		return
		
	logBookController.updateLogbook(encounter)
	
	DialogueManager.start_dialogue(encounter.dialogue)
	
	
	var choice:String=await DialogueManager.dialogue_finished
	
	await encounter_end_props(encounter, choice)

	day_results.append({
		"name": encounter.name,
		"status": encounter.status
	})

	GameState.encounter += 1

	if GameState.encounter > days[GameState.day - 1].encounters.size():
		await end_day()

	encounterOngoing = false


#func has_encounter() -> bool:
	#while GameState.day <= days.size():
		#var day = days[GameState.day - 1]
		#print(day.encounters.size())
	#
		#if GameState.encounter <= day.encounters.size():
			#
			#return true
#
		#if GameState.day == days.size():
		#
			#return false
#
		#GameState.day += 1
		#GameState.encounter = 1
	#
	#return false
	
	
func has_encounter() -> bool:
	while GameState.day <= days.size():
		var day = days[GameState.day - 1]

		if GameState.encounter <= day.encounters.size():
			return true

		return false

	return false
	
	
	

func move_customer(model:PackedScene,move_where:MovePosition):
	if move_where==MovePosition.MOVE_IN:
		var person:Node3D=model.instantiate()
		guestModel=person
		get_tree().current_scene.add_child(person)
		person.position=Vector3(-22.2,0,-6.22)
		var tween = create_tween()
		tween.tween_property(person, "position", Vector3(-3.249, -1.55, -3.682), 2.0)
		await tween.finished
		return person
	elif move_where==MovePosition.MOVE_OUT:
		var currPos=guestModel.position
		var tween = create_tween()
		tween.tween_property(guestModel, "position", Vector3(35.404, -1.556, -19.834), 2.0)
		await tween.finished
		guestModel.queue_free()
	
func wait_for_phone():
	phone.start_ringing()
	await phone.call_answered 



#to control whatever we wanna do at start of encounter
func encounter_startup_props(encounter:EncounterData):
	#logBookController.updateLogbook(encounter)
	await encounter_button.turnOff()
	pass


func encounter_end_props(encounter:EncounterData,choice:String):
	if encounter.communication_type=="VISITOR":
		move_customer(encounter.model,MovePosition.MOVE_OUT)
	match encounter.caller_type:
		"KILLER":
			match choice:
				"ACCEPT":
					encounter.status="FAIL"
				"REJECT":
					encounter.status="SUCCESS"
		"INNOCENT":
			match choice:
				"ACCEPT":
					encounter.status="SUCCESS"
				"REJECT":
					encounter.status="FAIL"
	await encounter_button.turnOn()
	pass
	

	
	
	
	
func end_day():
	var finished_day :int= GameState.day
	
	DayReportManager.add_report(finished_day, day_results)
	day_results.clear()
	print(DayReportManager.reports)
	await day_report_ui.show_report(
	DayReportManager.get_report(finished_day)
	)

	GameState.day += 1
	GameState.encounter = 1
	logBookController.add_page()

	
