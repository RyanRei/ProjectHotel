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
@export var tutorial:TutorialManager
enum MovePosition {
	MOVE_IN,
	MOVE_OUT
}

## Whether this day uses automatic time-based triggering or manual clock jumps (tutorial).
var is_tutorial_day := false
## Whether all encounters for the current day are finished and we're waiting for End Shift.
var waiting_for_end_shift := false
## Prevents the schedule watcher from starting the same encounter more than once
## while start_encounter() is awaiting its startup animation.
var encounter_starting := false


func _ready() -> void:
	encounter_button.startEncounter.connect(_on_end_shift_pressed)
	begin_day()


func begin_day() -> void:
	waiting_for_end_shift = false
	encounterOngoing = false
	encounter_starting = false
	is_tutorial_day = (GameState.day == 1)
	TimeManager.set_time(18, 0)
	encounter_button.set_hidden_immediately()

	if is_tutorial_day:
		TimeManager.pause()
		# The placeholder tutorial releases call one when its welcome is complete.
		# Future tutorial steps can call trigger_next_encounter() directly.
		await tutorial.welcome()
		trigger_next_encounter()
	else:
		TimeManager.resume_normal()


func _process(_delta: float) -> void:
	# Only auto-trigger on non-tutorial days when no encounter is active
	if is_tutorial_day:
		return
	if encounterOngoing or encounter_starting or waiting_for_end_shift:
		return
	if not has_encounter():
		return

	var encounter := get_current_encounter()
	if TimeManager.in_game_seconds >= encounter.get_trigger_seconds():
		start_encounter()


# ── Tutorial day: sequential encounter firing ───────────────────────

## Tutorial integration point. Jumps to the current encounter's authored time and
## starts it without resuming the fast clock. Safe to call more than once.
func trigger_next_encounter() -> void:
	if not is_tutorial_day or encounterOngoing or encounter_starting:
		return
	if not has_encounter():
		show_end_shift()
		return

	var encounter := get_current_encounter()
	# Jump the clock to this encounter's scheduled time
	TimeManager.set_time(encounter.trigger_hour, encounter.trigger_minute)
	start_encounter()


# ── Core encounter flow (shared by both modes) ─────────────────────

func get_current_encounter() -> EncounterData:
	return days[GameState.day - 1].encounters[GameState.encounter - 1]


func start_encounter() -> void:
	if encounterOngoing or encounter_starting:
		return
	if not has_encounter():
		return

	encounter_starting = true
	var encounter := get_current_encounter()

	await encounter_startup_props(encounter)
	encounter_starting = false
	encounterOngoing = true
	# Once an encounter is active, the clock advances at real-world speed.
	TimeManager.resume_encounter()

	if encounter.communication_type=="RESIDENT":
		await wait_for_phone()
	elif encounter.communication_type=="VISITOR":
		await move_customer(encounter.model,MovePosition.MOVE_IN)
	elif encounter.communication_type=="INFORMATIVE":
		await wait_for_phone()

		logBookController.updateLogbook(encounter)
		# For informative encounters, no dialogue — just show info and move on
		await finish_encounter(encounter, "NORMAL")
		return

	logBookController.updateLogbook(encounter)

	DialogueManager.start_dialogue(encounter.dialogue)

	var choice:String=await DialogueManager.dialogue_finished

	await finish_encounter(encounter, choice)


## Shared cleanup after an encounter resolves.
func finish_encounter(encounter: EncounterData, choice: String):
	await encounter_end_props(encounter, choice)

	day_results.append({
		"name": encounter.name,
		"status": encounter.status
	})

	GameState.encounter += 1
	encounterOngoing = false

	if GameState.encounter > days[GameState.day - 1].encounters.size():
		# All encounters done for the day
		if is_tutorial_day:
			show_end_shift()
		else:
			TimeManager.resume_normal()
			show_end_shift()
	else:
		# More encounters remain
		if is_tutorial_day:
			if GameState.encounter == 2:
				# The temporary tutorial ends after encounter one. From this point,
				# Shift 1 uses the same clock-driven scheduling as every other shift.
				is_tutorial_day = false
				TimeManager.resume_normal()
			else:
				TimeManager.pause()
		else:
			TimeManager.resume_normal()


func has_encounter() -> bool:
	if GameState.day > days.size():
		return false
	var day = days[GameState.day - 1]
	return GameState.encounter <= day.encounters.size()


# ── End Shift ───────────────────────────────────────────────────────

func show_end_shift() -> void:
	waiting_for_end_shift = true
	TimeManager.pause()
	await encounter_button.turnOnEndShift()

func _on_end_shift_pressed() -> void:
	if not waiting_for_end_shift:
		return
	waiting_for_end_shift = false
	await encounter_button.turnOff()
	TimeManager.set_time(6, 0)  # jump to 6 AM
	TimeManager.pause()
	await end_day()


# ── Encounter props (unchanged logic) ──────────────────────────────

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
func encounter_startup_props(_encounter: EncounterData) -> void:
	await encounter_button.turnOff()


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

	if GameState.day <= days.size():
		begin_day()
	else:
		TimeManager.pause()
