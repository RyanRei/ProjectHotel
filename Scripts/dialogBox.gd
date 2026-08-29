extends Control

@onready var text_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/Subtitles
@onready var continue_indicator: Label = $DialoguePanel/MarginContainer/VBoxContainer/ContinueIndicator
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@export var accept_reject: AcceptRejectButton
@export_range(10.0, 120.0, 1.0) var characters_per_second := 48.0

var typing := false
var reveal_text := ""
var awaiting_advance := false
var dialogue_choices: Array[DialogueChoice]
var selected_choice := 0
const CHOICE_BUTTON_SCENE := preload("res://Scenes/dialogue_choice_button.tscn")

var is_decision_pending := false
var is_hud_visible := true
var hint_label : Label

func _ready() -> void:
	if not InputMap.has_action("toggle_hud"):
		InputMap.add_action("toggle_hud")
		var evt = InputEventKey.new()
		evt.physical_keycode = KEY_TAB
		InputMap.action_add_event("toggle_hud", evt)
		
	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 24)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_label.position = Vector2(-20, -20)
	hint_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hint_label)
	hint_label.hide()
	
	DialogueManager.dialogue_started.connect(run_dialogue)
	DialogueManager.choices_requested.connect(show_choices)
	hide_dialogue_ui()

func hide_dialogue_ui() -> void:
	visible = false
	is_in_choices = false
	$DialoguePanel.hide()
	$Choices.hide()
	if hint_label: hint_label.hide()
	continue_indicator.hide()

var is_in_choices := false
var typing_skipped := false

func run_dialogue(current_node: DialogueNode):
	if not is_instance_valid(current_node):
		return

	visible = true
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
		audio_stream_player.stop()
	elif remaining_time > 0.0:
		await get_tree().create_timer(maxf(remaining_time, 0.15)).timeout

	continue_indicator.show()
	await wait_for_advance()

	if current_node.wait_for_prompt:
		text_label.text = "What would you like to do?"
		continue_indicator.hide()
		
		is_decision_pending = true
		is_hud_visible = true
		is_in_choices = false
		hint_label.text = "[TAB] Inspect Desk"
		hint_label.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		accept_reject.turnOn(DialogueManager.has_active_choices())
		var choice_made: String = await accept_reject.choiceMade
		
		is_decision_pending = false
		hint_label.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		accept_reject.turnOff()
		await hide_line()
		DialogueManager.advance(choice_made)
	else:
		await hide_line()
		DialogueManager.advance()

func toggle_action_hud():
	if not is_decision_pending: return
	is_hud_visible = !is_hud_visible
	
	if is_hud_visible:
		$DialoguePanel.show()
		if is_in_choices:
			if $Choices.get_child_count() > 0:
				$Choices.show()
		else:
			accept_reject.show()
			accept_reject.active = true
			
		hint_label.text = "[TAB] Inspect Desk"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		$DialoguePanel.hide()
		if is_in_choices:
			$Choices.hide()
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
	is_decision_pending = true
	is_hud_visible = true
	is_in_choices = true
	hint_label.text = "[TAB] Inspect Desk"
	hint_label.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	dialogue_choices = choices
	selected_choice = 0
	$DialoguePanel.show()
	$Choices.show()
	$Choices.modulate.a = 0.0

	for child in $Choices.get_children():
		child.queue_free()

	for choice in choices:
		var choice_button: DialogueChoiceButton = CHOICE_BUTTON_SCENE.instantiate()
		choice_button.set_choice(choice)
		$Choices.add_child(choice_button)

	update_choice_display()
	var tween := create_tween()
	tween.tween_property($Choices, "modulate:a", 1.0, 0.18)

func _input(event):
	if event.is_action_pressed("toggle_hud") and is_decision_pending:
		toggle_action_hud()
		get_viewport().set_input_as_handled()
		return

	if is_decision_pending and not is_hud_visible:
		return

	if not visible:
		return

	if not $Choices.visible:
		if event.is_action_pressed("Confirm"):
			if typing:
				typing = false
				text_label.text = reveal_text
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
		
		$Choices.hide()
		DialogueManager.choose(choice)
		get_viewport().set_input_as_handled()

func update_choice_display():
	for i in dialogue_choices.size():
		var choice_button: DialogueChoiceButton = $Choices.get_child(i)
		choice_button.set_selected(i == selected_choice)

func _unhandled_input(event: InputEvent) -> void:
	if typing and event.is_action_pressed("Confirm"):
		typing = false
		text_label.text = reveal_text
		get_viewport().set_input_as_handled()
