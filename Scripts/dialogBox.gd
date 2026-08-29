extends Control

@onready var text_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/Subtitles
@onready var continue_indicator: Label = $DialoguePanel/MarginContainer/VBoxContainer/ContinueIndicator
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var question_menu: VBoxContainer = $QuestionMenu
@onready var question_back: Button = $QuestionMenu/QuestionBack
@onready var choices_container: VBoxContainer = $QuestionMenu/Choices
@export var accept_reject: AcceptRejectButton
@export_range(10.0, 120.0, 1.0) var characters_per_second := 48.0

var typing := false
var waiting_for_line_audio := false
var reveal_text := ""
var awaiting_advance := false
var dialogue_choices: Array[DialogueChoice]
var selected_choice := 0
const CHOICE_BUTTON_SCENE := preload("res://Scenes/dialogue_choice_button.tscn")
const HUD_FONT := preload("res://Assets/Fonts/ShareTechMono-Regular.ttf")

var is_decision_pending := false
var is_hud_visible := true
var hint_label : Label
var confirmation_text_generation := 0

func _ready() -> void:
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
	DialogueManager.choices_requested.connect(show_choices)
	accept_reject.confirmation_requested.connect(_on_confirmation_requested)
	accept_reject.confirmation_cancelled.connect(_on_confirmation_cancelled)
	hide_dialogue_ui()


func _on_confirmation_requested(message: String) -> void:
	confirmation_text_generation += 1
	_type_confirmation(message, confirmation_text_generation)


func _on_confirmation_cancelled() -> void:
	confirmation_text_generation += 1
	text_label.text = "What would you like to do?"


func _type_confirmation(message: String, generation: int) -> void:
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
	visible = false
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

	visible = true
	is_hud_visible = true
	GameState.leave_desk_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$DialoguePanel.show()
	$DialoguePanel.modulate.a = 1.0
	var line_started_at := Time.get_ticks_msec()
	var line_duration := current_node.duration

	if current_node.voiceline:
		audio_stream_player.stream = current_node.voiceline
		audio_stream_player.play()
		line_duration = maxf(line_duration, current_node.voiceline.get_length())

	await show_line(current_node.text)
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

	continue_indicator.show()
	await wait_for_advance()
	# This is the final advance press for the displayed line. Stop its voice
	# whether the next state hides the box or replaces it with the action prompt.
	audio_stream_player.stop()

	if current_node.wait_for_prompt:
		await present_action_prompt()
	else:
		await hide_line()
		DialogueManager.advance()


func present_action_prompt() -> void:
	visible = true
	GameState.leave_desk_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$DialoguePanel.show()
	$DialoguePanel.modulate.a = 1.0
	question_menu.hide()
	text_label.text = "What would you like to do?"
	continue_indicator.hide()
	is_decision_pending = true
	is_hud_visible = true
	is_in_choices = false
	hint_label.text = "[TAB] Inspect Desk"
	hint_label.show()
	accept_reject.show()
	accept_reject.turnOn(DialogueManager.get_remaining_question_count())

	var choice_made: String = await accept_reject.choiceMade
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

func wait_for_advance() -> void:
	awaiting_advance = true
	while awaiting_advance:
		await get_tree().process_frame

func show_line(text: String):
	reveal_text = text
	text_label.text = ""
	continue_indicator.hide()
	typing = true
	awaiting_advance = false
	typing_skipped = false

	for character_index in text.length():
		if not typing:
			typing_skipped = true
			break
		text_label.text = text.substr(0, character_index + 1)
		await get_tree().create_timer(1.0 / characters_per_second).timeout

	text_label.text = reveal_text
	typing = false

func hide_line():
	audio_stream_player.stop()
	var tween = create_tween()
	tween.tween_property($DialoguePanel, "modulate:a", 0.0, 0.25)
	await tween.finished
	hide_dialogue_ui()
	return tween

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
	hint_label.show()

	dialogue_choices = choices
	selected_choice = 0
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
	if event.is_action_pressed("toggle_hud") and DialogueManager.active:
		toggle_action_hud()
		get_viewport().set_input_as_handled()
		return

	if not is_hud_visible:
		return

	if not visible:
		return

	if is_in_choices and event.is_action_pressed("Cancel Decision"):
		return_to_action_hud()
		get_viewport().set_input_as_handled()
		return

	if not question_menu.visible:
		if event.is_action_pressed("Confirm"):
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
		selected_choice = max(0, selected_choice - 1)
		update_choice_display()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Move Down"):
		selected_choice = min(dialogue_choices.size() - 1, selected_choice + 1)
		update_choice_display()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Confirm"):
		if dialogue_choices.is_empty():
			return
		var choice = dialogue_choices[selected_choice]
		
		is_decision_pending = false
		is_in_choices = false
		hint_label.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		question_menu.hide()
		DialogueManager.choose(choice)
		get_viewport().set_input_as_handled()

func update_choice_display():
	for i in dialogue_choices.size():
		var choice_button: DialogueChoiceButton = choices_container.get_child(i)
		choice_button.set_selected(i == selected_choice)


func return_to_action_hud() -> void:
	is_in_choices = false
	question_menu.hide()
	present_action_prompt()


func _on_question_back_pressed() -> void:
	if is_in_choices:
		return_to_action_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_hud_visible and typing and event.is_action_pressed("Confirm"):
		typing = false
		text_label.text = reveal_text
		get_viewport().set_input_as_handled()
