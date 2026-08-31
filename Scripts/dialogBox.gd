class_name DialogBox
extends Control

@onready var text_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/Subtitles
@onready var speaker_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var continue_indicator: Label = $DialoguePanel/MarginContainer/VBoxContainer/ContinueIndicator
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var question_menu: VBoxContainer = $QuestionMenu
@onready var question_back: Button = $QuestionMenu/QuestionBack
@onready var choices_container: VBoxContainer = $QuestionMenu/Choices
@onready var history_indicator: Control = $HistoryIndicator
@onready var history_overlay: DialogueHistory = $HistoryOverlay
@export var accept_reject: AcceptRejectButton
@export_range(10.0, 120.0, 1.0) var characters_per_second := 48.0

@export var tutorial:TutorialManager
signal confirmqn #for tutorial
signal tab_checked
signal history_opened
signal history_closed
var tutorial_check_tab_active := false
var move_up_locked := false
var move_down_locked := false
var confirm_locked := false
var toggle_hud_locked := false
var typing := false
var waiting_for_line_audio := false
var reveal_text := ""
var awaiting_advance := false
var dialogue_choices: Array[DialogueChoice]
var selected_choice := 0
const CHOICE_BUTTON_SCENE := preload("res://Scenes/dialogue_choice_button.tscn")
const HUD_FONT := preload("res://Assets/Fonts/ShareTechMono-Regular.ttf")
const DEFAULT_ACTION_PROMPT := "What would you like to do?"

var is_decision_pending := false
var is_hud_visible := true
var hint_label : Label
var confirmation_text_generation := 0
var history_open := false
var history_previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var dialogue_generation := 0
var tutorial_line_active := false
var tutorial_line_allow_navigation := false
var tab_feature_available := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not InputMap.has_action("toggle_hud"):
		InputMap.add_action("toggle_hud")
		var evt = InputEventKey.new()
		evt.physical_keycode = KEY_TAB
		InputMap.action_add_event("toggle_hud", evt)
		
	hint_label = Label.new()
	hint_label.add_theme_font_override("font", HUD_FONT)
	hint_label.add_theme_font_size_override("font_size", 21)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_label.position = Vector2(-20, -20)
	hint_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hint_label)
	hint_label.hide()
	
	DialogueManager.dialogue_started.connect(run_dialogue)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.choices_requested.connect(show_choices)
	accept_reject.confirmation_requested.connect(_on_confirmation_requested)
	accept_reject.confirmation_cancelled.connect(_on_confirmation_cancelled)
	hide_dialogue_ui()


func _on_dialogue_finished(choice: String) -> void:
	if choice == "SECRET_CANCELLED":
		dialogue_generation += 1
		is_decision_pending = false
		is_in_choices = false
		question_menu.hide()
		accept_reject.active = false
		accept_reject.hide()
	_stop_voice_players()
	typing = false
	waiting_for_line_audio = false
	awaiting_advance = false
	hide_dialogue_ui()


func _on_confirmation_requested(message: String) -> void:
	confirmation_text_generation += 1
	_type_confirmation(message, confirmation_text_generation)


func _on_confirmation_cancelled() -> void:
	confirmation_text_generation += 1
	text_label.text = DEFAULT_ACTION_PROMPT


func _type_confirmation(message: String, generation: int) -> void:
	message = _hud_text_or_default(message)
	text_label.text = ""
	for character_index in message.length():
		if generation != confirmation_text_generation:
			return
		text_label.text = message.substr(0, character_index + 1)
		await get_tree().create_timer(1.0 / characters_per_second).timeout
	if generation == confirmation_text_generation:
		text_label.text = message

func hide_dialogue_ui() -> void:
	confirmation_text_generation += 1
	GameState.enter_desk_state()
	visible = true
	is_in_choices = false
	$DialoguePanel.hide()
	question_menu.hide()
	if hint_label: hint_label.hide()
	continue_indicator.hide()

var is_in_choices := false
var typing_skipped := false

func run_dialogue(current_node: DialogueNode):
	if not is_instance_valid(current_node):
		return
	dialogue_generation += 1
	var run_generation := dialogue_generation

	visible = true
	is_hud_visible = true
	GameState.leave_desk_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$DialoguePanel.show()
	$DialoguePanel.modulate.a = 1.0
	speaker_label.text = DialogueManager.current_speaker_name
	var line_started_at := Time.get_ticks_msec()
	var line_duration := current_node.duration

	if current_node.voiceline:
		_play_voice(current_node.voiceline)
		line_duration = maxf(line_duration, current_node.voiceline.get_length())

	await show_line(current_node.text)
	if run_generation != dialogue_generation or not DialogueManager.active or current_node != DialogueManager.current_node:
		return
	history_overlay.add_guest_message(DialogueManager.current_speaker_name, current_node.text)
	var remaining_time := line_duration - (Time.get_ticks_msec() - line_started_at) / 1000.0
	
	if typing_skipped:
		# Revealing the full text does not cut the voice. The clip is stopped
		# only when the player advances and the dialogue box begins to close.
		pass
	elif remaining_time > 0.0:
		waiting_for_line_audio = true
		var audio_deadline := Time.get_ticks_msec() + int(maxf(remaining_time, 0.15) * 1000.0)
		while waiting_for_line_audio and Time.get_ticks_msec() < audio_deadline:
			await get_tree().process_frame
		waiting_for_line_audio = false
	if run_generation != dialogue_generation or not DialogueManager.active or current_node != DialogueManager.current_node:
		return
	if current_node.auto_advance:
		await hide_line()
		DialogueManager.advance()
		return

	continue_indicator.show()
	await wait_for_advance()
	if run_generation != dialogue_generation or not DialogueManager.active or current_node != DialogueManager.current_node:
		return
	# This is the final advance press for the displayed line. Stop its voice
	# whether the next state hides the box or replaces it with the action prompt.
	_stop_voice_players()

	if current_node.wait_for_prompt:
		if current_node.question_only_prompt and not current_node.choices.is_empty():
			DialogueManager.current_active_choices = current_node.choices.duplicate()
			show_choices(DialogueManager.current_active_choices)
		else:
			await present_action_prompt(run_generation)
	else:
		await hide_line()
		DialogueManager.advance()


## Plays a voiced tutorial interstitial in the normal dialogue box without
## replacing DialogueManager.current_node. The active encounter remains paused
## underneath and resumes from the exact same decision state afterward.
func play_tutorial_line(node: DialogueNode, allow_question_navigation := false) -> void:
	if not is_instance_valid(node):
		return
	var previous_hud_visibility := is_hud_visible
	var previous_desk_state := GameState.desk_state
	var previous_mouse_mode := Input.mouse_mode
	var previous_hud_text := text_label.text
	var previous_speaker_text := speaker_label.text
	tutorial_line_active = true
	tutorial_line_allow_navigation = allow_question_navigation
	visible = true
	is_hud_visible = true
	GameState.leave_desk_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$DialoguePanel.show()
	$DialoguePanel.modulate.a = 1.0
	speaker_label.text = "Manager"
	continue_indicator.hide()
	var line_started_at := Time.get_ticks_msec()
	var line_duration := node.duration
	if node.voiceline:
		_play_voice(node.voiceline)
		line_duration = maxf(line_duration, node.voiceline.get_length())
	await show_line(node.text)
	history_overlay.add_guest_message("Manager", node.text)
	var remaining_time := line_duration - (Time.get_ticks_msec() - line_started_at) / 1000.0
	if not typing_skipped and remaining_time > 0.0:
		waiting_for_line_audio = true
		var audio_deadline := Time.get_ticks_msec() + int(maxf(remaining_time, 0.15) * 1000.0)
		while waiting_for_line_audio and Time.get_ticks_msec() < audio_deadline:
			await get_tree().process_frame
		waiting_for_line_audio = false
	continue_indicator.show()
	await wait_for_advance()
	_stop_voice_players()
	continue_indicator.hide()
	var tween := create_tween()
	tween.tween_property($DialoguePanel, "modulate:a", 0.0, 0.15)
	await tween.finished
	$DialoguePanel.hide()
	$DialoguePanel.modulate.a = 1.0
	tutorial_line_active = false
	tutorial_line_allow_navigation = false
	text_label.text = _hud_text_or_default(previous_hud_text)
	speaker_label.text = previous_speaker_text
	is_hud_visible = previous_hud_visibility
	if previous_desk_state:
		GameState.enter_desk_state()
	else:
		GameState.leave_desk_state()
	Input.mouse_mode = previous_mouse_mode


func show_tutorial_action_prompt(message: String) -> void:
	visible = true
	is_hud_visible = true
	GameState.leave_desk_state()
	$DialoguePanel.show()
	$DialoguePanel.modulate.a = 1.0
	speaker_label.text = ""
	text_label.text = _hud_text_or_default(message)
	continue_indicator.hide()
	question_menu.hide()
	hint_label.hide()
	accept_reject.show()
	accept_reject.active = true


func set_tutorial_choice_index(index: int) -> void:
	selected_choice = clampi(index, 0, maxi(dialogue_choices.size() - 1, 0))
	update_choice_display(false)


func present_action_prompt(run_generation := dialogue_generation) -> void:
	visible = true
	GameState.leave_desk_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$DialoguePanel.show()
	$DialoguePanel.modulate.a = 1.0
	question_menu.hide()
	text_label.text = DEFAULT_ACTION_PROMPT
	continue_indicator.hide()
	is_decision_pending = true
	is_hud_visible = true
	is_in_choices = false
	hint_label.text = "[TAB] Inspect Desk"
	if tab_feature_available:
		hint_label.show()
	else:
		hint_label.hide()
	accept_reject.show()
	
		
	accept_reject.turnOn(DialogueManager.get_remaining_question_count())
	if GameState.day==1 and GameState.encounter==1 and not tutorial.skipped:
		if tutorial.question_asked == 1:
			tutorial.question_asked += 1
			await tutorial.introduce_tabs()
		elif tutorial.question_asked == 2 and tutorial.should_check_tab:
			tutorial.question_asked += 1
			await tutorial.check_tab_button()
	
	if GameState.day == 1 and GameState.encounter == 2 and not tutorial.skipped:
		if not tutorial.daniel_intro_complete:
			await tutorial.enc2QuestionPointer()
	if GameState.day == 1 and GameState.encounter == 3 and not tutorial.skipped:
		if not tutorial.maya_hud_initialized:
			await tutorial.enc3QuestionPointer()
	if GameState.day == 1 and GameState.encounter == 4 and not tutorial.skipped:
		if not tutorial.arthur_hud_initialized:
			tutorial.initialize_arthur_tutorial()
		
	var choice_made: String = await accept_reject.choiceMade
	if run_generation != dialogue_generation or not DialogueManager.active:
		return
	if choice_made == "ACCEPT" or choice_made == "REJECT":
		history_overlay.add_decision(choice_made)
	is_decision_pending = false
	hint_label.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await accept_reject.turnOff()
	await hide_line()
	DialogueManager.advance(choice_made)

func toggle_action_hud():
	if not DialogueManager.active:
		return
	is_hud_visible = !is_hud_visible
	
	if is_hud_visible:
		GameState.leave_desk_state()
		if is_decision_pending:
			if is_in_choices:
				$DialoguePanel.hide()
				if choices_container.get_child_count() > 0:
					question_menu.show()
			else:
				$DialoguePanel.show()
				if not accept_reject.is_confirming_decision():
					text_label.text = DEFAULT_ACTION_PROMPT
				accept_reject.show()
				accept_reject.active = true
		else:
			$DialoguePanel.show()
			
		hint_label.text = "[TAB] Inspect Desk"
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		GameState.enter_desk_state()
		$DialoguePanel.hide()
		if is_decision_pending:
			if is_in_choices:
				question_menu.hide()
			else:
				accept_reject.hide()
				accept_reject.active = false
			
		hint_label.text = "[TAB] Open Actions"
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if tab_feature_available:
		hint_label.show()
	else:
		hint_label.hide()

func lock_move_up() -> void:
	move_up_locked = true

func unlock_move_up() -> void:
	move_up_locked = false

func lock_move_down() -> void:
	move_down_locked = true

func unlock_move_down() -> void:
	move_down_locked = false

func lock_confirm() -> void:
	confirm_locked = true

func unlock_confirm() -> void:
	confirm_locked = false

func lock_toggle_hud() -> void:
	toggle_hud_locked = true

func unlock_toggle_hud() -> void:
	toggle_hud_locked = false


func set_tab_feature_available(value: bool) -> void:
	tab_feature_available = value
	if not is_instance_valid(hint_label):
		return
	if not value:
		hint_label.hide()
	elif is_decision_pending:
		hint_label.text = "[TAB] Inspect Desk" if is_hud_visible else "[TAB] Open Actions"
		hint_label.show()

func wait_for_advance() -> void:
	awaiting_advance = true
	while awaiting_advance:
		await get_tree().process_frame

func show_line(text: String):
	reveal_text = _hud_text_or_default(text)
	text_label.text = ""
	continue_indicator.hide()
	typing = true
	awaiting_advance = false
	typing_skipped = false

	for character_index in reveal_text.length():
		if not typing:
			typing_skipped = true
			break
		text_label.text = reveal_text.substr(0, character_index + 1)
		await get_tree().create_timer(1.0 / characters_per_second).timeout

	text_label.text = reveal_text
	typing = false


func _hud_text_or_default(value: String) -> String:
	return DEFAULT_ACTION_PROMPT if value.strip_edges().is_empty() else value

func hide_line():
	_stop_voice_players()
	var tween = create_tween()
	tween.tween_property($DialoguePanel, "modulate:a", 0.0, 0.25)
	await tween.finished
	hide_dialogue_ui()
	return tween


func _play_voice(stream: AudioStream) -> void:
	_stop_voice_players()
	var spatial_player := DialogueManager.current_spatial_voice_player
	if is_instance_valid(spatial_player):
		spatial_player.stream = stream
		spatial_player.play()
		return
	audio_stream_player.stream = stream
	audio_stream_player.play()


func _stop_voice_players() -> void:
	audio_stream_player.stop()
	var spatial_player := DialogueManager.current_spatial_voice_player
	if is_instance_valid(spatial_player):
		spatial_player.stop()

func show_choices(choices: Array[DialogueChoice]):
	
	if choices.is_empty():
		hide_dialogue_ui()
		return
	visible = true
	GameState.leave_desk_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_decision_pending = true
	is_hud_visible = true
	is_in_choices = true
	hint_label.text = "[TAB] Inspect Desk"
	if tab_feature_available:
		hint_label.show()
	else:
		hint_label.hide()

	dialogue_choices = choices
	selected_choice = 0
	if GameState.day==1 and GameState.encounter==2 :
		if  tutorial.question_asked==2 or tutorial.question_asked==3:
	
			selected_choice=1
	$DialoguePanel.hide()
	question_menu.show()
	question_menu.modulate.a = 0.0

	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()

	for choice in choices:
		var choice_button: DialogueChoiceButton = CHOICE_BUTTON_SCENE.instantiate()
		choice_button.set_choice(choice)
		choices_container.add_child(choice_button)

	update_choice_display()
	var tween := create_tween()
	tween.tween_property(question_menu, "modulate:a", 1.0, 0.18)

func _input(event):
	if tutorial_line_active:
		if event.is_action_pressed("Move Up") and tutorial_line_allow_navigation:
			selected_choice = max(0, selected_choice - 1)
			update_choice_display(false)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("Move Down") and tutorial_line_allow_navigation:
			selected_choice = min(dialogue_choices.size() - 1, selected_choice + 1)
			update_choice_display(false)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("Confirm"):
			if typing:
				typing = false
				text_label.text = reveal_text
			elif waiting_for_line_audio:
				waiting_for_line_audio = false
			elif awaiting_advance:
				awaiting_advance = false
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("History"):
		# The roster owns all keyboard input while its monitor is open. In
		# particular, typing "T" into its search field must not open history.
		for roster_ui in get_tree().get_nodes_in_group("roster_ui"):
			if roster_ui is CanvasItem and (roster_ui as CanvasItem).visible:
				return
		if DialogueManager.active and DialogueManager.current_node != null and DialogueManager.current_node.unskippable:
			get_viewport().set_input_as_handled()
			return
		if tutorial != null and tutorial.is_tutorial_prompt_active():
			get_viewport().set_input_as_handled()
			return
		toggle_history()
		get_viewport().set_input_as_handled()
		return

	if history_open:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				history_overlay.scroll_by(-90)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				history_overlay.scroll_by(90)
				get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.is_action_pressed("Move Up") or event.is_action_pressed("ui_up"):
				history_overlay.scroll_by(-70)
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("Move Down") or event.is_action_pressed("ui_down"):
				history_overlay.scroll_by(70)
				get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_hud") and DialogueManager.active:
		if not tab_feature_available:
			get_viewport().set_input_as_handled()
			return
		if DialogueManager.current_node != null and DialogueManager.current_node.unskippable:
			get_viewport().set_input_as_handled()
			return
		if toggle_hud_locked:
			get_viewport().set_input_as_handled()
			return
		if tutorial_check_tab_active:
			tutorial_check_tab_active = false
			tab_checked.emit()
		toggle_action_hud()
		get_viewport().set_input_as_handled()
		return

	if not is_hud_visible:
		return

	if not visible:
		return

	if is_in_choices and event.is_action_pressed("Cancel Decision"):
		if accept_reject.canceled_locked:
			return
		return_to_action_hud()
		get_viewport().set_input_as_handled()
		return

	if not question_menu.visible:
		if event.is_action_pressed("Confirm"):
			if DialogueManager.current_node != null and DialogueManager.current_node.unskippable and (typing or waiting_for_line_audio):
				get_viewport().set_input_as_handled()
				return
			if confirm_locked:
				get_viewport().set_input_as_handled()
				return
			if typing:
				typing = false
				text_label.text = reveal_text
				get_viewport().set_input_as_handled()
			elif waiting_for_line_audio:
				waiting_for_line_audio = false
				get_viewport().set_input_as_handled()
			elif awaiting_advance:
				awaiting_advance = false
				get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Move Up"):
		if move_up_locked:
			get_viewport().set_input_as_handled()
			return
		selected_choice = max(0, selected_choice - 1)
		update_choice_display(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Move Down"):
		if move_down_locked:
			get_viewport().set_input_as_handled()
			return
		
		selected_choice = min(dialogue_choices.size() - 1, selected_choice + 1)
		update_choice_display(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Confirm"):
		if confirm_locked:
			get_viewport().set_input_as_handled()
			return
		if dialogue_choices.is_empty():
			return
		var choice = dialogue_choices[selected_choice]
		if tutorial != null and not tutorial.can_select_dialogue_choice(choice):
			tutorial.on_blocked_dialogue_choice()
			get_viewport().set_input_as_handled()
			return
		if tutorial != null:
			tutorial.on_dialogue_choice_selected(choice)
		history_overlay.add_player_message(choice.text)
		
		is_decision_pending = false
		is_in_choices = false
		hint_label.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		question_menu.hide()
		DialogueManager.choose(choice)
		confirmqn.emit()
		get_viewport().set_input_as_handled()

func update_choice_display(run_tutorial_hook := true):
	for i in dialogue_choices.size():
		var choice_button: DialogueChoiceButton = choices_container.get_child(i)
		choice_button.set_selected(i == selected_choice)
	if run_tutorial_hook and GameState.day==1 and GameState.encounter==1 and not tutorial.skipped:
		if tutorial.question_asked==2:
			await tutorial.select_question()

	elif run_tutorial_hook and GameState.day == 1 and GameState.encounter == 2 and not tutorial.skipped:
		if tutorial.daniel_tutorial_active:
			tutorial.enc2SelectQuestion()
			
	elif run_tutorial_hook and GameState.day == 1 and GameState.encounter == 3 and not tutorial.skipped:
		if tutorial.maya_tutorial_active:
			tutorial.enc3SelectQuestion()
		


func return_to_action_hud() -> void:
	is_in_choices = false
	question_menu.hide()
	present_action_prompt()


func _on_question_back_pressed() -> void:
	if is_in_choices:
		return_to_action_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_hud_visible and typing and event.is_action_pressed("Confirm"):
		if DialogueManager.current_node != null and DialogueManager.current_node.unskippable:
			get_viewport().set_input_as_handled()
			return
		typing = false
		text_label.text = reveal_text
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var tutorial_prompt_active := tutorial != null and tutorial.is_tutorial_prompt_active()
	var consequence_cutscene := DialogueManager.active and DialogueManager.current_node != null and DialogueManager.current_node.unskippable
	history_indicator.visible = not history_open and not tutorial_prompt_active and not consequence_cutscene







func toggle_history() -> void:
	history_open = not history_open
	history_overlay.visible = history_open
	if history_open:
		history_opened.emit()
		history_previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		accept_reject.active = false
		history_overlay.scroll_to_latest()
	else:
		history_closed.emit()
		Input.mouse_mode = history_previous_mouse_mode
		accept_reject.active = is_decision_pending and not is_in_choices and accept_reject.visible
