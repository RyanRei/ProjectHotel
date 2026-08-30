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
@export var shift_transition_ui: Control
@export var guestModel:Node3D
@export var tutorial:TutorialManager
enum MovePosition {
	MOVE_IN,
	MOVE_INSIDE,
	MOVE_BACK_OUT
}

@export_group("Visitor Movement")
@export var visitor_scale := Vector3.ONE
@export var visitor_entry_position := Vector3(0.0, -1.55, -36.0)
@export var visitor_lobby_entry_position := Vector3(0.0, -1.55, -29.5)
@export var visitor_desk_position := Vector3(-3.249, -1.55, -3.682)
@export var visitor_right_turn_position := Vector3(10.5, -1.55, -6.0)
@export var visitor_inside_position := Vector3(19.5, -1.55, -8.0)
@export_range(1.0, 10.0, 0.25) var visitor_walk_speed := 4.5
@export_range(1.0, 12.0, 0.5) var visitor_turn_speed := 5.0

## Whether this day uses automatic time-based triggering or manual clock jumps (tutorial).
var is_tutorial_day := false
## Whether all encounters for the current day are finished and we're waiting for End Shift.
var waiting_for_end_shift := false
## Prevents the schedule watcher from starting the same encounter more than once
## while start_encounter() is awaiting its startup animation.
var encounter_starting := false
var encounter_generation := 0


func _ready() -> void:
	MusicManager.play_gameplay()
	encounter_button.startEncounter.connect(_on_end_shift_pressed)
	if not TimeManager.shift_ended.is_connected(_on_clock_shift_ended):
		TimeManager.shift_ended.connect(_on_clock_shift_ended)
	begin_day()


func begin_day() -> void:
	waiting_for_end_shift = false
	encounterOngoing = false
	encounter_starting = false
	is_tutorial_day = (GameState.day == 1)
	TimeManager.set_time(18, 0)
	encounter_button.set_hidden_immediately()
	if GameState.day == 2:
		GameState.story_flags.clear()
	if GameState.day > 1 and shift_transition_ui != null and shift_transition_ui.has_method("play_shift_intro"):
		TimeManager.pause()
		await shift_transition_ui.call("play_shift_intro", GameState.day)

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
	_skip_unavailable_encounters()
	if not has_encounter():
		show_end_shift()
		return

	var encounter := get_current_encounter()
	if TimeManager.in_game_seconds >= encounter.get_trigger_seconds():
		start_encounter()


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.is_pressed() or key_event.is_echo():
		return
	if not key_event.ctrl_pressed or not key_event.shift_pressed:
		return
	if key_event.physical_keycode == KEY_N:
		_request_secret_encounter_navigation(1)
		get_viewport().set_input_as_handled()
	elif key_event.physical_keycode == KEY_P:
		_request_secret_encounter_navigation(-1)
		get_viewport().set_input_as_handled()


func _request_secret_encounter_navigation(direction: int) -> void:
	if GameState.day < 1 or GameState.day > days.size():
		return
	var encounter_count := days[GameState.day - 1].encounters.size()
	var target := clampi(GameState.encounter + direction, 1, encounter_count + 1)
	encounter_generation += 1
	waiting_for_end_shift = false
	if tutorial != null:
		tutorial.reset_after_secret_navigation()
	is_tutorial_day = false
	if DialogueManager.active:
		DialogueManager.end_dialogue("SECRET_CANCELLED")
	if phone != null and (phone.ringing or phone.answering):
		phone.skip_ringing()
	if is_instance_valid(guestModel):
		guestModel.queue_free()
		guestModel = null
	encounterOngoing = false
	encounter_starting = false
	if target > encounter_count:
		GameState.encounter = encounter_count + 1
		show_end_shift()
		return
	GameState.encounter = target
	var encounter := get_current_encounter()
	TimeManager.set_time(encounter.trigger_hour, encounter.trigger_minute)
	TimeManager.pause()
	call_deferred("start_encounter")


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
	if GameState.day==1 and not tutorial.skipped:
		tutorial.question_asked=1
		if GameState.encounter==2:
		
			sendClockFinished.emit()
	encounter_starting = true
	encounter_generation += 1
	var run_generation := encounter_generation
	var encounter := get_current_encounter()

	await encounter_startup_props(encounter)
	if run_generation != encounter_generation:
		return
	encounter_starting = false
	encounterOngoing = true
	# Once an encounter is active, the clock advances at real-world speed.
	TimeManager.resume_encounter()

	var communication_type := _get_communication_type(encounter)
	if communication_type=="RESIDENT":
		await wait_for_phone()
	elif communication_type=="VISITOR":
		await move_customer(_get_visitor_model(encounter), MovePosition.MOVE_IN)
		if run_generation != encounter_generation:
			return
		if GameState.day==1 and GameState.encounter==3 and not tutorial.skipped:
			await tutorial.mayaChenIntroduction(guestModel)
	elif communication_type=="INFORMATIVE":
		await wait_for_phone()
		if run_generation != encounter_generation:
			return
		logBookController.updateLogbook(encounter)
		# For informative encounters, no dialogue — just show info and move on
		await finish_encounter(encounter, "NORMAL")
		return

	if run_generation != encounter_generation:
		return

	logBookController.updateLogbook(encounter)

	DialogueManager.start_dialogue(_get_dialogue(encounter), encounter.name)

	var choice:String=await DialogueManager.dialogue_finished
	if run_generation != encounter_generation:
		return

	# Some residents provide information only once access has actually been
	# authorized. Keep that dialogue out of the verification phase.
	if choice == "ACCEPT" and encounter.accepted_dialogue != null:
		DialogueManager.start_dialogue(encounter.accepted_dialogue, encounter.name)
		await DialogueManager.dialogue_finished
		if run_generation != encounter_generation:
			return
	
	await finish_encounter(encounter, choice)


## Shared cleanup after an encounter resolves.
func finish_encounter(encounter: EncounterData, choice: String):
	await encounter_end_props(encounter, choice)

	_store_story_choice(encounter, choice)
	if _is_reportable(encounter):
		day_results.append({
			"id": encounter.encounter_id,
			"name": encounter.name,
			"status": encounter.status,
			"consequence": _get_consequence(encounter, choice),
			"weight": encounter.report_weight
		})
	if GameState.encounter==1 and GameState.day==1 and not tutorial.skipped:
		await tutorial.introduce_clock()
	if GameState.encounter == 4 and GameState.day == 1 and not tutorial.skipped:
		await tutorial.show_final_shift_tutorial()
	GameState.encounter += 1
	_skip_unavailable_encounters()
	encounterOngoing = false
	
	if GameState.encounter > days[GameState.day - 1].encounters.size():
		# All encounters done for the day
		if GameState.day == 1:
			show_end_shift()
		else:
			TimeManager.resume_normal()
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


func _skip_unavailable_encounters() -> void:
	while has_encounter():
		var candidate := get_current_encounter()
		match candidate.encounter_id:
			"caleb_taunt":
				# The final call only happens when Ven was admitted and the
				# impersonator was subsequently allowed through as Caleb.
				if not bool(GameState.story_flags.get("ven_admitted", false)) or not bool(GameState.story_flags.get("caleb_admitted", false)):
					GameState.encounter += 1
					continue
		return


func _get_dialogue(encounter: EncounterData) -> DialogueNode:
	if encounter.encounter_id == "caleb" and not bool(GameState.story_flags.get("ven_admitted", false)):
		return encounter.alternate_dialogue
	return encounter.dialogue


func _get_communication_type(encounter: EncounterData) -> String:
	if encounter.encounter_id == "caleb" and not bool(GameState.story_flags.get("ven_admitted", false)):
		return "RESIDENT"
	return encounter.communication_type


func _store_story_choice(encounter: EncounterData, choice: String) -> void:
	match encounter.encounter_id:
		"ven_keer":
			GameState.story_flags["ven_admitted"] = choice == "ACCEPT"
			if choice != "ACCEPT":
				GameState.story_flags["ven_outside_death"] = true
		"caleb":
			GameState.story_flags["caleb_admitted"] = choice == "ACCEPT"
			if bool(GameState.story_flags.get("ven_admitted", false)) and choice == "ACCEPT":
				GameState.story_flags["ven_inside_death"] = true


func _is_reportable(encounter: EncounterData) -> bool:
	if not encounter.reportable:
		return false
	if encounter.encounter_id == "caleb" and not bool(GameState.story_flags.get("ven_admitted", false)):
		return false
	return true


# ── End Shift ───────────────────────────────────────────────────────

func show_end_shift() -> void:
	if waiting_for_end_shift:
		return
	waiting_for_end_shift = true
	TimeManager.pause()
	await encounter_button.turnOnEndShift()


func _on_clock_shift_ended() -> void:
	if not encounterOngoing and not encounter_starting and not has_encounter():
		show_end_shift()

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
		var lobby := _get_reception_lobby()
		if lobby != null:
			await lobby.open_entrance()
		await _walk_guest_path(person, PackedVector3Array([visitor_lobby_entry_position]))
		if lobby != null:
			await lobby.close_entrance()
		await _walk_guest_path(person, PackedVector3Array([visitor_desk_position]))
		await _turn_guest_toward(person, Vector3.ZERO)
		_play_guest_animation(person, "Idle")
		return person

	if not is_instance_valid(guestModel):
		return null

	if move_where == MovePosition.MOVE_INSIDE:
		# Accepted visitors pivot right, cross the side passage and enter the lift.
		var lobby := _get_reception_lobby()
		if lobby != null:
			await lobby.open_elevator()
		await _walk_guest_path(guestModel, PackedVector3Array([
			visitor_right_turn_position,
			visitor_inside_position
		]))
		guestModel.queue_free()
		guestModel = null
		if lobby != null:
			await lobby.close_elevator()
		return null
	elif move_where == MovePosition.MOVE_BACK_OUT:
		# Rejected visitors retrace the route and leave through the glass doors.
		var lobby := _get_reception_lobby()
		if lobby != null:
			await lobby.open_entrance()
		await _walk_guest_path(guestModel, PackedVector3Array([
			visitor_lobby_entry_position,
			visitor_entry_position
		]))
		if lobby != null:
			await lobby.close_entrance()

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
		# Remove the final floating-point remainder without snapping during the walk.
		person.position = target


func _get_reception_lobby() -> ReceptionLobby:
	return get_tree().get_first_node_in_group("reception_lobby") as ReceptionLobby


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
	animation_name = _get_stabilized_animation(person, player, animation_name)
	if player.is_playing() and player.current_animation == animation_name:
		return
	var animation := player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR
	player.play(animation_name, 0.18)


## The male source animations contain world-like translation on the hips bone.
## Since the encounter manager already moves the visitor root, that translation
## causes the visible mesh to jump whenever the clip loops or changes. Runtime
## copies retain all limb animation while holding the hips at the clip's initial
## local position.
func _get_stabilized_animation(person: Node3D, player: AnimationPlayer, source_name: StringName) -> StringName:
	if person.name != &"MaleVisitor":
		return source_name

	const LIBRARY_NAME := &"stable_motion"
	var local_name := StringName(String(source_name).replace("/", "_") + "_root_locked")
	var full_name := StringName("%s/%s" % [LIBRARY_NAME, local_name])
	if player.has_animation(full_name):
		return full_name

	var source := player.get_animation(source_name)
	if source == null:
		return source_name
	if not player.has_animation_library(LIBRARY_NAME):
		player.add_animation_library(LIBRARY_NAME, AnimationLibrary.new())
	var library := player.get_animation_library(LIBRARY_NAME)
	var stabilized := source.duplicate(true) as Animation
	for track_index in stabilized.get_track_count():
		if stabilized.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		if "mixamorig_Hips" not in String(stabilized.track_get_path(track_index)):
			continue
		if stabilized.track_get_key_count(track_index) == 0:
			continue
		var locked_position: Vector3 = stabilized.track_get_key_value(track_index, 0)
		for key_index in stabilized.track_get_key_count(track_index):
			stabilized.track_set_key_value(track_index, key_index, locked_position)
	library.add_animation(local_name, stabilized)
	return full_name


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
		if GameState.encounter==1 and not tutorial.skipped:
			await tutorial.introduce_phone()
			return
	
	await phone.call_answered


#to control whatever we wanna do at start of encounter
func encounter_startup_props(_encounter: EncounterData) -> void:
	await encounter_button.turnOff()


func encounter_end_props(encounter:EncounterData,choice:String):
	if _get_communication_type(encounter)=="VISITOR":
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
	if choice == "NORMAL":
		encounter.status = "SUCCESS"


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

	# The Shift 2 newspaper is the final Win/Game Over screen. Once the player
	# closes it, return directly to the main menu instead of starting another day.
	if finished_day >= days.size():
		TimeManager.pause()
		GameState.day = 1
		GameState.encounter = 1
		GameState.story_flags.clear()
		GameState.enter_desk_state()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		return

	GameState.day += 1
	GameState.encounter = 1
	logBookController.add_page()

	if GameState.day <= days.size():
		begin_day()
	else:
		TimeManager.pause()
