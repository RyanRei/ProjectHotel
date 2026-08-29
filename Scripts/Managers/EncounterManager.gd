class_name EncounterManager
extends Node

const MALE_VISITOR_SCENE: PackedScene = preload("res://Scenes/humanEntity.tscn")
const FEMALE_VISITOR_SCENE: PackedScene = preload("res://Scenes/femaleEntity.tscn")
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
	MOVE_INSIDE,
	MOVE_BACK_OUT
}

@export_group("Visitor Movement")
@export var visitor_scale := Vector3.ONE
@export var visitor_entry_position := Vector3(-22.2, -1.55, -6.22)
@export var visitor_desk_position := Vector3(-3.249, -1.55, -1.25)
@export var visitor_right_turn_position := Vector3(-3.249, -1.55, -11.0)
@export var visitor_inside_position := Vector3(35.404, -1.55, -19.834)
@export_range(1.0, 10.0, 0.25) var visitor_walk_speed := 4.5
@export_range(1.0, 12.0, 0.5) var visitor_turn_speed := 5.0

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
	if GameState.day==1:
		tutorial.question_asked=1
		if GameState.encounter==2:
		
			sendClockFinished.emit()
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
		if GameState.day==1 and GameState.encounter==3:
			await tutorial.mayaChenIntroduction(guestModel)
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
		"status": encounter.status,
		"consequence": _get_consequence(encounter, choice)
	})
	if GameState.encounter==1 and GameState.day==1:
		tutorial.introduce_clock()
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
#tutorialsignal:
signal sendClockFinished
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

func move_customer(
	model: PackedScene,
	move_where: MovePosition
) -> Node3D:
	if move_where == MovePosition.MOVE_IN:
		if model == null:
			return null
		var person := model.instantiate() as Node3D
		if person == null:
			return null
		guestModel = person
		get_tree().current_scene.add_child(person)
		person.scale = visitor_scale
		person.position = visitor_entry_position
		await _walk_guest_path(person, PackedVector3Array([visitor_desk_position]))
		await _turn_guest_toward(person, Vector3.ZERO)
		_play_guest_animation(person, "Idle")
		return person

	if not is_instance_valid(guestModel):
		return null

	if move_where == MovePosition.MOVE_INSIDE:
		# Accepted visitors pivot right at the desk, then continue into the shelter.
		await _walk_guest_path(guestModel, PackedVector3Array([
			visitor_right_turn_position,
			visitor_inside_position
		]))
	elif move_where == MovePosition.MOVE_BACK_OUT:
		# Rejected visitors turn around and retrace their path to the entrance.
		await _walk_guest_path(guestModel, PackedVector3Array([visitor_entry_position]))

	guestModel.queue_free()
	guestModel = null
	return null


func _walk_guest_path(person: Node3D, points: PackedVector3Array) -> void:
	_play_guest_animation(person, "Walk")
	for target in points:
		while person.position.distance_to(target) > 0.025:
			await get_tree().process_frame
			if not is_instance_valid(person):
				return
			var delta := get_process_delta_time()
			var offset := target - person.position
			var distance := offset.length()
			var step := minf(visitor_walk_speed * delta, distance)
			person.position += offset.normalized() * step
			var desired_y := _guest_facing_y(person, target)
			person.rotation.y = lerp_angle(person.rotation.y, desired_y, minf(visitor_turn_speed * delta, 1.0))
		person.position = target


func _turn_guest_toward(person: Node3D, target: Vector3) -> void:
	var start_y := person.rotation.y
	var desired_y := _guest_facing_y(person, target)
	var target_y := start_y + wrapf(desired_y - start_y, -PI, PI)
	var turn_tween := create_tween()
	turn_tween.tween_property(person, "rotation:y", target_y, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await turn_tween.finished


func _guest_facing_y(person: Node3D, target: Vector3) -> float:
	var flat_target := Vector3(target.x, person.global_position.y, target.z)
	if person.global_position.distance_squared_to(flat_target) <= 0.001:
		return person.rotation.y
	var facing_transform := person.global_transform.looking_at(flat_target, Vector3.UP, true)
	return facing_transform.basis.get_euler().y


func _play_guest_animation(person: Node3D, requested_name: StringName) -> void:
	var players := person.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	var animation_name := _resolve_guest_animation(player, requested_name)
	if animation_name == &"":
		return
	if player.is_playing() and player.current_animation == animation_name:
		return
	var animation := player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR
	player.play(animation_name, 0.18)


func _resolve_guest_animation(player: AnimationPlayer, requested_name: StringName) -> StringName:
	if player.has_animation(requested_name):
		return requested_name
	var requested_lower := String(requested_name).to_lower()
	for candidate in player.get_animation_list():
		var candidate_lower := String(candidate).to_lower()
		if candidate_lower == requested_lower or candidate_lower.ends_with("_" + requested_lower):
			return candidate
	return &""


func _get_visitor_model(encounter: EncounterData) -> PackedScene:
	if encounter.visitor_gender == "FEMALE":
		return FEMALE_VISITOR_SCENE
	if encounter.visitor_gender == "MALE":
		return MALE_VISITOR_SCENE
	return encounter.model

func wait_for_phone():
	phone.start_ringing()
	if is_tutorial_day:
		if GameState.encounter==1:
			await tutorial.introduce_phone()
			return
	
	await phone.call_answered


#to control whatever we wanna do at start of encounter
func encounter_startup_props(_encounter: EncounterData) -> void:
	await encounter_button.turnOff()


func encounter_end_props(encounter:EncounterData,choice:String):
	if encounter.communication_type=="VISITOR":
		if choice == "ACCEPT":
			await move_customer(_get_visitor_model(encounter), MovePosition.MOVE_INSIDE)
		else:
			await move_customer(_get_visitor_model(encounter), MovePosition.MOVE_BACK_OUT)
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


func _get_consequence(encounter: EncounterData, choice: String) -> String:
	# A rejected innocent is exposed to danger outside. An admitted killer
	# reaches the resident's room, so an inside crime takes place.
	if encounter.caller_type == "KILLER" and choice == "ACCEPT":
		return "INSIDE"
	if encounter.caller_type == "INNOCENT" and choice == "REJECT":
		return "OUTSIDE"
	return "NONE"


func end_day():
	var finished_day :int= GameState.day

	DayReportManager.add_report(finished_day, day_results)
	day_results.clear()
	
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
