class_name TutorialManager
extends Node

const TUTORIAL_FONT := preload("res://Assets/Fonts/ShareTechMono-Regular.ttf")
const TUTORIAL_TEXT := Color("dce8e3")
const TUTORIAL_ACCENT := Color("e6c968")
const TUTORIAL_BORDER := Color("526b70")
const TUTORIAL_PANEL := Color(0.012, 0.018, 0.021, 0.96)
const TUTORIAL_DIM := Color(0.004, 0.007, 0.009, 0.84)
const MANAGER_OPENING := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Opening/start.tres")
const MANAGER_LOGBOOK := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Logbook/start.tres")
const MANAGER_COMPUTER := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Computer/start.tres")
const TRACEY_ACCEPT_REJECT := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/accept_reject.tres")
const TRACEY_PICKUP := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/pickup.tres")
const TRACEY_HUD_OVERVIEW := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/hud_overview.tres")
const TRACEY_QUESTIONS_INTRO := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/questions_intro.tres")
const TRACEY_QUESTION_NAVIGATION := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/question_navigation.tres")
const TRACEY_RESERVATION := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/reservation.tres")
const TRACEY_VERIFY := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/AfterQuestion/verify.tres")
const TRACEY_TAB_INSTRUCTION := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/AfterQuestion/tab_instruction.tres")
const TRACEY_LOGBOOK_CHECK := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/Verification/logbook.tres")
const TRACEY_COMPUTER_CHECK := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/Verification/computer.tres")
const TRACEY_RETURN_NUDGE := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/Verification/return_nudge.tres")
const TRACEY_ACCEPTED_CLOCK := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/AfterDecision/accepted.tres")
const TRACEY_REJECTED_CLOCK := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter1/AfterDecision/rejected.tres")
const DANIEL_HISTORY_INTRO := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/history_intro.tres")
const DANIEL_FLOW_INTRO := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/flow_intro.tres")
const DANIEL_DECISION_BLOCKED := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/decision_blocked.tres")
const DANIEL_RECOMMENDED_QUESTIONS := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/recommended_questions.tres")
const DANIEL_WRONG_QUESTION := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/wrong_question.tres")
const DANIEL_COMPUTER_CHECK := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/computer.tres")
const DANIEL_LOGBOOK_CHECK := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/logbook.tres")
const DANIEL_RETURN_NUDGE := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter2/return_nudge.tres")
const DANIEL_QUESTION_CHECK_IN := preload("res://Assets/ItemHolders/Dialogues/Day1/DanielReeves/player questions/q2.tres")
const DANIEL_QUESTION_COMPANION := preload("res://Assets/ItemHolders/Dialogues/Day1/DanielReeves/player questions/q3.tres")
const MAYA_VISITOR_INTRO := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter3/visitor_intro.tres")
const MAYA_QUESTION_GUIDANCE := preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter3/question_guidance.tres")
const MAYA_QUESTION_RELATIONSHIP := preload("res://Assets/ItemHolders/Dialogues/Day1/MayaChen/player questions/q3.tres")
const MAYA_QUESTION_EXPECTED_TIME := preload("res://Assets/ItemHolders/Dialogues/Day1/MayaChen/player questions/q4.tres")
const MIDNIGHT_SYNC_INTRO: DialogueNode = preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter4/midnight_sync.tres")
const ARTHUR_COMPUTER_CHECK: DialogueNode = preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter4/computer.tres")
const ARTHUR_SYNC_RESULT: DialogueNode = preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter4/sync_result.tres")
const FINAL_SHIFT_ONE: DialogueNode = preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter4/final_one.tres")
const FINAL_SHIFT_TWO: DialogueNode = preload("res://Assets/ItemHolders/Dialogues/Tutorial/Manager/Encounter4/final_two.tres")

@export var encounterManager:EncounterManager
@export var clock:WallClockController
@export var computahUi:RosterUI
@export var computah:ComputerMonitor
@export var dialog_tutorial: Control
@export var camera:DeskCameraController
@export var phone_light:SpotLight3D
@export var logbook_light:SpotLight3D
@export var pc_light:SpotLight3D
@export var clock_light:SpotLight3D
@export var panelTexts:Control
@export var logBook:LogbookController
@export var loggBookUi:LogbookUI
@export var pointer:TutorialPointer3D
#@export var logbookTutorial:Control
@export var phone_tutorial:Control
@export var phone:Phone
@export var normal_lights:Node3D
@export var world_dimmer:CanvasLayer
@export  var tab_explanation:Control
@export var accept_reject_buttons:AcceptRejectButton
@export var dialogBox:DialogBox

var question_asked:=1
var should_check_tab := false
var check_tab_button_active := false
var continuation_hint: Label
var dimmer_panels: Array[ColorRect] = []
var spotlight_mask: ColorRect
var spotlight_targets: Array[Control] = []
var instruction_hint := ""
var encounter_four_update_shown := false
var skipped := false
var tool_walkthrough_active := false
var logbook_walkthrough_complete := false
var computer_walkthrough_complete := false
var tool_dialogue_running := false
var quest_panel: PanelContainer
var quest_heading: Button
var quest_details: VBoxContainer
var quest_heading_title := "QUICK RUNDOWN"
var quest_collapsed := false
var quest_logbook: Label
var quest_computer: Label
var quest_decision: Label
var tutorial_dialogue_stack: VBoxContainer
var opening_call_connected := false
var tutorial_allowed_actions: Array[StringName] = []
var tracey_verification_active := false
var tracey_logbook_checked := false
var tracey_computer_checked := false
var verification_dialogue_running := false
var verification_focus_generation := 0
var tracey_final_quests_active := false
var tracey_optional_question_done := false
var daniel_tutorial_active := false
var daniel_intro_complete := false
var daniel_questions_asked: Array[DialogueChoice] = []
var daniel_logbook_checked := false
var daniel_resident_record_checked := false
var daniel_room_record_checked := false
var daniel_logbook_dialogue_shown := false
var daniel_computer_dialogue_shown := false
var daniel_interstitial_running := false
var daniel_warning_entry: Dictionary = {}
var daniel_warning_generation := 0
var daniel_recommendation_entry: Dictionary = {}
var daniel_last_tool_activity_msec := 0
var daniel_idle_nudge_played := false
var daniel_idle_desk_active := false
var maya_tutorial_active := false
var maya_hud_initialized := false
var maya_question_guidance_shown := false
var maya_guidance_entry: Dictionary = {}
var maya_questions_asked: Array[DialogueChoice] = []
var maya_logbook_checked := false
var maya_computer_record_checked := false
var midnight_sync_shown := false
var midnight_sync_running := false
var arthur_tutorial_active := false
var arthur_hud_initialized := false
var arthur_questions_asked: Array[DialogueChoice] = []
var arthur_logbook_checked := false
var arthur_record_checked := false
var arthur_computer_dialogue_shown := false
var arthur_sync_dialogue_shown := false
var arthur_interstitial_running := false

signal tool_walkthrough_completed
signal skip_tutorial_selected(should_skip: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world_dimmer.layer = 10
	var tutorial_canvas := tab_explanation.get_parent() as CanvasLayer
	if tutorial_canvas != null:
		tutorial_canvas.layer = 11
	_style_tutorial_tree(tab_explanation)
	_style_tutorial_tree(phone_tutorial)
	_style_tutorial_tree(panelTexts)
	_style_opening_dialog()
	_create_continuation_hint()
	_create_spotlight_dimmer()
	_create_tool_quest_panel()
	tab_explanation.get_node("opening").hide()
	world_dimmer.hide()
	if not computah.computer_clicked.is_connected(_on_tutorial_computer_clicked):
		computah.computer_clicked.connect(_on_tutorial_computer_clicked)
	if not loggBookUi.logbook_opened.is_connected(_on_walkthrough_logbook_clicked):
		loggBookUi.logbook_opened.connect(_on_walkthrough_logbook_clicked)
	if not computahUi.roster_opened.is_connected(_on_walkthrough_computer_opened):
		computahUi.roster_opened.connect(_on_walkthrough_computer_opened)
	if not phone.call_answered.is_connected(_on_any_phone_answered):
		phone.call_answered.connect(_on_any_phone_answered)
	if not DialogueManager.dialogue_started.is_connected(_on_tutorial_dialogue_started):
		DialogueManager.dialogue_started.connect(_on_tutorial_dialogue_started)
	if not accept_reject_buttons.choiceMade.is_connected(_on_tracey_tutorial_choice):
		accept_reject_buttons.choiceMade.connect(_on_tracey_tutorial_choice)
	if not accept_reject_buttons.locked_decision_attempted.is_connected(_on_locked_decision_attempted):
		accept_reject_buttons.locked_decision_attempted.connect(_on_locked_decision_attempted)
	if not computahUi.record_selected.is_connected(_on_computer_record_selected):
		computahUi.record_selected.connect(_on_computer_record_selected)
	if not computahUi.computah_closed.is_connected(_on_tutorial_tool_closed):
		computahUi.computah_closed.connect(_on_tutorial_tool_closed)
	if not loggBookUi.logbookClosed.is_connected(_on_tutorial_tool_closed):
		loggBookUi.logbookClosed.connect(_on_tutorial_tool_closed)
	if not TimeManager.midnight_reached.is_connected(_on_midnight_reached):
		TimeManager.midnight_reached.connect(_on_midnight_reached)


func _create_tool_quest_panel() -> void:
	quest_panel = PanelContainer.new()
	quest_panel.name = "TutorialToolQuest"
	quest_panel.z_index = 80
	quest_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quest_panel.position = Vector2(-300.0, 22.0)
	quest_panel.custom_minimum_size = Vector2(300.0, 0.0)
	quest_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	quest_panel.add_theme_stylebox_override("panel", _make_text_panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	quest_panel.add_child(column)
	quest_heading = Button.new()
	quest_heading.flat = true
	quest_heading.alignment = HORIZONTAL_ALIGNMENT_LEFT
	quest_heading.focus_mode = Control.FOCUS_NONE
	quest_heading.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	quest_heading.tooltip_text = "Hide or show objectives"
	quest_heading.add_theme_font_override("font", TUTORIAL_FONT)
	quest_heading.add_theme_font_size_override("font_size", 13)
	quest_heading.add_theme_color_override("font_color", TUTORIAL_ACCENT)
	quest_heading.pressed.connect(_toggle_quest_panel)
	column.add_child(quest_heading)
	quest_details = VBoxContainer.new()
	quest_details.add_theme_constant_override("separation", 5)
	column.add_child(quest_details)
	quest_logbook = _make_quest_label()
	quest_computer = _make_quest_label()
	quest_decision = _make_quest_label()
	quest_details.add_child(quest_logbook)
	quest_details.add_child(quest_computer)
	quest_details.add_child(quest_decision)
	tab_explanation.get_parent().add_child.call_deferred(quest_panel)
	quest_panel.hide()
	_update_tool_quest()

	tutorial_dialogue_stack = VBoxContainer.new()
	tutorial_dialogue_stack.name = "TutorialDialogueStack"
	tutorial_dialogue_stack.z_index = 79
	tutorial_dialogue_stack.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tutorial_dialogue_stack.position = Vector2(-400.0, 142.0)
	tutorial_dialogue_stack.size = Vector2(376.0, 420.0)
	tutorial_dialogue_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_dialogue_stack.add_theme_constant_override("separation", 8)
	tab_explanation.get_parent().add_child.call_deferred(tutorial_dialogue_stack)
	_refresh_quest_panel_layout()


func _set_quest_heading(title: String) -> void:
	quest_heading_title = title
	_refresh_quest_panel_layout()


func _toggle_quest_panel() -> void:
	quest_collapsed = not quest_collapsed
	_refresh_quest_panel_layout()


func _refresh_quest_panel_layout() -> void:
	if not is_instance_valid(quest_panel) or not is_instance_valid(quest_heading):
		return
	quest_heading.text = ("▸ " if quest_collapsed else "▾ ") + quest_heading_title
	if is_instance_valid(quest_details):
		quest_details.visible = not quest_collapsed
	quest_panel.reset_size()
	_update_tutorial_stack_position.call_deferred()


func _update_tutorial_stack_position() -> void:
	if not is_instance_valid(tutorial_dialogue_stack) or not is_instance_valid(quest_panel):
		return
	var panel_bottom := 22.0
	if quest_panel.visible:
		panel_bottom = quest_panel.position.y + quest_panel.size.y + 12.0
	tutorial_dialogue_stack.position.y = panel_bottom


func _make_quest_label() -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", TUTORIAL_FONT)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TUTORIAL_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _update_tool_quest() -> void:
	_set_quest_heading("QUICK RUNDOWN")
	quest_logbook.show()
	quest_computer.show()
	quest_decision.hide()
	quest_logbook.text = ("[x] " if logbook_walkthrough_complete else "[ ] ") + "Interact with the logbook"
	quest_computer.text = ("[x] " if computer_walkthrough_complete else "[ ] ") + "Interact with the computer"
	_refresh_quest_panel_layout()
	if logbook_walkthrough_complete and computer_walkthrough_complete:
		quest_panel.hide()
		tool_walkthrough_active = false
		logbook_light.hide()
		pc_light.hide()
		normal_lights.show()
		tool_walkthrough_completed.emit()


func _show_verification_quest() -> void:
	_set_quest_heading("VERIFY CALLER")
	quest_logbook.text = "[ ] Verify her against computer & logbook"
	quest_logbook.show()
	quest_computer.hide()
	quest_decision.hide()
	quest_panel.show()
	_refresh_quest_panel_layout()
	normal_lights.hide()
	logbook_light.show()
	pc_light.show()


func _create_floating_tutorial_dialogue(node: DialogueNode) -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(376.0, 64.0)
	panel.add_theme_stylebox_override("panel", _make_text_panel_style())
	var label := Label.new()
	label.text = node.text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", TUTORIAL_FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", TUTORIAL_TEXT)
	panel.add_child(label)
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_child(player)
	tutorial_dialogue_stack.add_child(panel)
	if node.voiceline != null:
		player.stream = node.voiceline
		player.play()
	return {"panel":panel, "player":player}


func play_tutorial_notice(node: DialogueNode) -> void:
	var entry := _create_floating_tutorial_dialogue(node)
	var hold_time := node.duration
	if node.voiceline != null:
		hold_time = maxf(hold_time, node.voiceline.get_length())
	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout
	_fade_floating_tutorial_dialogue(entry, 1.0)


func show_bounded_tutorial_dialogue(node: DialogueNode) -> Dictionary:
	return _create_floating_tutorial_dialogue(node)


func dismiss_tutorial_dialogue(entry: Dictionary) -> void:
	await _fade_floating_tutorial_dialogue(entry, 0.0)


func _fade_floating_tutorial_dialogue(entry: Dictionary, delay: float) -> void:
	var panel := entry.get("panel") as PanelContainer
	var player := entry.get("player") as AudioStreamPlayer
	if not is_instance_valid(panel):
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if is_instance_valid(player) and player.playing:
		player.stop()
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.28)
	await tween.finished
	panel.queue_free()


func _process(_delta: float) -> void:
	_update_continuation_hint()
	_update_spotlight_dimmer()
	_update_daniel_idle_nudge()


func _style_tutorial_tree(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_font_override("font", TUTORIAL_FONT)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", TUTORIAL_TEXT)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		if panel.name == "box":
			panel.add_theme_stylebox_override("panel", _make_highlight_style())
		else:
			panel.add_theme_stylebox_override("panel", _make_text_panel_style())
			if panel.size.x > 600.0:
				panel.size.x = 560.0
	elif node is Panel and node.name == "pointer":
		var pointer_panel := node as Panel
		var pointer_style := StyleBoxFlat.new()
		pointer_style.bg_color = TUTORIAL_ACCENT
		pointer_panel.add_theme_stylebox_override("panel", pointer_style)

	for child in node.get_children():
		_style_tutorial_tree(child)


func _make_text_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TUTORIAL_PANEL
	style.border_color = TUTORIAL_BORDER
	style.set_border_width_all(2)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 11.0
	style.content_margin_bottom = 11.0
	return style


func _make_highlight_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	return style


func _style_opening_dialog() -> void:
	var opening := tab_explanation.get_node("opening") as Control
	var panel := opening.get_node("PanelContainer") as PanelContainer
	var label := panel.get_node("Label") as Label
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.02, 0.024, 0.88)
	style.border_color = Color(0.34, 0.42, 0.43, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(32.0, 408.0)
	panel.size = Vector2(1088.0, 208.0)
	label.add_theme_font_size_override("font_size", 26)


func _create_continuation_hint() -> void:
	continuation_hint = Label.new()
	continuation_hint.name = "TutorialContinueHint"
	continuation_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continuation_hint.z_index = 100
	continuation_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	continuation_hint.offset_left = -300.0
	continuation_hint.offset_top = -28.0
	continuation_hint.offset_right = 300.0
	continuation_hint.offset_bottom = -7.0
	continuation_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continuation_hint.add_theme_font_override("font", TUTORIAL_FONT)
	continuation_hint.add_theme_font_size_override("font_size", 13)
	continuation_hint.add_theme_color_override("font_color", TUTORIAL_ACCENT)
	tab_explanation.get_parent().add_child.call_deferred(continuation_hint)


func _create_spotlight_dimmer() -> void:
	for child in world_dimmer.get_children():
		if child is CanvasItem:
			(child as CanvasItem).hide()

	spotlight_mask = ColorRect.new()
	spotlight_mask.name = "TutorialSpotlightMask"
	spotlight_mask.color = Color.WHITE
	spotlight_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform int hole_count = 0;
uniform vec4 holes[8];
uniform vec4 dim_color : source_color = vec4(0.004, 0.007, 0.009, 0.90);
void fragment() {
	float alpha = dim_color.a;
	for (int index = 0; index < 8; index++) {
		if (index >= hole_count) { break; }
		vec4 hole = holes[index];
		if (UV.x >= hole.x && UV.y >= hole.y && UV.x <= hole.z && UV.y <= hole.w) {
			alpha = 0.0;
		}
	}
	COLOR = vec4(dim_color.rgb, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	spotlight_mask.material = material
	world_dimmer.add_child.call_deferred(spotlight_mask)


func _update_continuation_hint() -> void:
	if not is_instance_valid(continuation_hint):
		return
	var hint := _get_current_hint()
	continuation_hint.text = hint
	continuation_hint.visible = not hint.is_empty()


func _get_current_hint() -> String:
	if not instruction_hint.is_empty():
		return instruction_hint
	var hints := {
		"opening": "CLICK TO CONTINUE",
		"logbookleft": "CLICK TO CONTINUE",
		"logbookright": "CLICK TO CONTINUE",
		"acceptReject": "CLICK TO CONTINUE",
		"question": "[Q]  ASK A QUESTION",
		"q1tracey": "[F]  SELECT THE HIGHLIGHTED QUESTION",
		"checktab": "[TAB]  ENTER DESK MODE",
		"itmatches": "[ESC]  CLOSE THE COMPUTER",
		"clockticks": "CLICK TO CONTINUE",
		"ENC2/questionPointer": "[Q]  ASK A QUESTION",
		"ENC2/q1daniel": "[F]  SELECT THE HIGHLIGHTED QUESTION",
		"ENC2/checktab": "[TAB]  ENTER DESK MODE",
		"ENC2/becareful": "[ESC]  CLOSE THE LOGBOOK",
		"ENC3/mayaChenIntro": "CLICK TO CONTINUE",
		"ENC3/questionPointer": "[Q]  ASK A QUESTION",
		"ENC3/q1maya": "[F]  SELECT THE HIGHLIGHTED QUESTION",
	}
	for path in hints:
		var step := tab_explanation.get_node_or_null(path) as Control
		if step != null and step.is_visible_in_tree():
			return hints[path]
	if phone_tutorial.is_visible_in_tree():
		return "CLICK THE RINGING PHONE"
	return ""


func _update_spotlight_dimmer() -> void:
	if not is_instance_valid(spotlight_mask) or not world_dimmer.visible:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	spotlight_mask.position = Vector2.ZERO
	spotlight_mask.size = viewport_size
	var visible_targets: Array[Control] = []
	for target in spotlight_targets:
		if is_instance_valid(target) and target.is_visible_in_tree():
			visible_targets.append(target)
	if visible_targets.is_empty():
		var fallback := _find_visible_highlight(tab_explanation)
		if fallback != null:
			visible_targets.append(fallback)
	var holes := PackedVector4Array()
	for index in range(mini(visible_targets.size(), 8)):
		var target: Control = visible_targets[index]
		var cutout: Rect2 = target.get_global_rect().grow(6.0).intersection(Rect2(Vector2.ZERO, viewport_size))
		holes.append(Vector4(
			cutout.position.x / viewport_size.x,
			cutout.position.y / viewport_size.y,
			cutout.end.x / viewport_size.x,
			cutout.end.y / viewport_size.y
		))
	while holes.size() < 8:
		holes.append(Vector4.ZERO)
	var material := spotlight_mask.material as ShaderMaterial
	material.set_shader_parameter("hole_count", mini(visible_targets.size(), 8))
	material.set_shader_parameter("holes", holes)


## Standard tutorial spotlight API. Multiple nearby controls are exposed as one
## clear region while the rest of the screen is heavily dimmed.
func show_spotlight(targets: Array[Control]) -> void:
	spotlight_targets = targets.duplicate()
	world_dimmer.show()


func clear_spotlight() -> void:
	spotlight_targets.clear()
	world_dimmer.hide()
	world_dimmer.layer = 10


func transition_spotlight(from_target: Control, to_target: Control, persistent_targets: Array[Control] = []) -> void:
	var proxy := Control.new()
	proxy.name = "SpotlightTransitionProxy"
	proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_explanation.get_parent().add_child(proxy)
	var start_rect := from_target.get_global_rect()
	var end_rect := to_target.get_global_rect()
	proxy.position = start_rect.position
	proxy.size = start_rect.size
	spotlight_targets = [proxy]
	spotlight_targets.append_array(persistent_targets)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(proxy, "position", end_rect.position, 0.24)
	tween.tween_property(proxy, "size", end_rect.size, 0.24)
	await tween.finished
	proxy.queue_free()
	spotlight_targets = [to_target]
	spotlight_targets.append_array(persistent_targets)


func _find_visible_highlight(node: Node) -> Control:
	if node is Control and node.name == "box" and (node as Control).is_visible_in_tree():
		return node as Control
	for child in node.get_children():
		var result := _find_visible_highlight(child)
		if result != null:
			return result
	return null


func _set_dimmer_rects(screen: Rect2, cutout: Rect2) -> void:
	if cutout.size == Vector2.ZERO:
		dimmer_panels[0].position = screen.position
		dimmer_panels[0].size = screen.size
		for index in range(1, 4):
			dimmer_panels[index].size = Vector2.ZERO
		return

	var right_edge := cutout.position.x + cutout.size.x
	var bottom_edge := cutout.position.y + cutout.size.y
	var rectangles := [
		Rect2(0.0, 0.0, screen.size.x, cutout.position.y),
		Rect2(0.0, bottom_edge, screen.size.x, maxf(0.0, screen.size.y - bottom_edge)),
		Rect2(0.0, cutout.position.y, cutout.position.x, cutout.size.y),
		Rect2(right_edge, cutout.position.y, maxf(0.0, screen.size.x - right_edge), cutout.size.y),
	]
	for index in range(4):
		dimmer_panels[index].position = rectangles[index].position
		dimmer_panels[index].size = rectangles[index].size

signal mouse_clicked
func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo \
		and key_event.ctrl_pressed and key_event.shift_pressed:
		if key_event.physical_keycode == KEY_N:
			encounterManager._request_secret_encounter_navigation(1)
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode == KEY_P:
			encounterManager._request_secret_encounter_navigation(-1)
			get_viewport().set_input_as_handled()
			return
	if skipped:
		return
	# Communication History owns navigation and wheel input while open. Quest
	# guidance must never intercept scrolling inside it.
	if dialogBox.history_open:
		return
	# An open computer owns keyboard input. Tutorial prompts may remain visible,
	# but must never swallow LineEdit typing or prevent free investigation.
	if computahUi.visible:
		return
	# Tutorial locks can keep the player inside a required question flow, but an
	# accept/reject confirmation must always allow X to return to the main HUD.
	if event.is_action_pressed("Cancel Decision") \
		and accept_reject_buttons != null \
		and accept_reject_buttons.is_confirming_decision():
		return
	var rule := _get_prompt_input_rule()
	if not rule.active:
		return
	if event is InputEventMouseMotion:
		return
	if event is InputEventMouseButton:
		if rule.allow_mouse:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				mouse_clicked.emit()
			return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		for action in rule.actions:
			if event.is_action_pressed(action):
				return
		get_viewport().set_input_as_handled()


func is_tutorial_prompt_active() -> bool:
	if skipped:
		return false
	return bool(_get_prompt_input_rule().active)


func _get_prompt_input_rule() -> Dictionary:
	if not tutorial_allowed_actions.is_empty():
		return {"active":true, "allow_mouse":false, "actions":tutorial_allowed_actions}
	var mouse_steps := [
		"opening",
		"logbookleft",
		"logbookright",
		"acceptReject",
		"ENC3/mayaChenIntro",
	]
	for path in mouse_steps:
		if _tutorial_step_visible(path):
			return {"active":true, "allow_mouse":true, "actions":[]}

	var action_steps := {
		"question": [&"Question"],
		"q1tracey": [&"Confirm"],
		"checktab": [&"toggle_hud"],
		"itmatches": [&"ui_cancel"],
		"ENC2/questionPointer": [&"Question"],
		"ENC2/q1daniel": [&"Confirm"],
		"ENC2/checktab": [&"toggle_hud"],
		"ENC2/becareful": [&"ui_cancel"],
		"ENC3/questionPointer": [&"Question"],
		"ENC3/q1maya": [&"Confirm"],
	}
	for path in action_steps:
		if _tutorial_step_visible(path):
			return {"active":true, "allow_mouse":path in ["itmatches", "ENC2/becareful"], "actions":action_steps[path]}

	if _tutorial_step_visible("clockticks"):
		return {"active":true, "allow_mouse":true, "actions":[]}
	if phone_tutorial.is_visible_in_tree():
		return {"active":true, "allow_mouse":true, "actions":[]}
	if not instruction_hint.is_empty() or pointer.target != null:
		return {"active":true, "allow_mouse":true, "actions":[]}
	if world_dimmer.visible:
		return {"active":true, "allow_mouse":false, "actions":[]}
	return {"active":false, "allow_mouse":false, "actions":[]}


func _tutorial_step_visible(path: NodePath) -> bool:
	var step := tab_explanation.get_node_or_null(path) as Control
	return step != null and step.is_visible_in_tree()


func welcome():
	# The Manager uses the same DialogueManager and dialogue box as encounters.
	# Each authored DialogueNode owns its text and its optional voice clip.
	opening_call_connected = false
	phone.start_ringing()
	await get_tree().create_timer(1.0).timeout
	if phone.ringing:
		phone.answer()
	while not opening_call_connected:
		await get_tree().process_frame
	MusicManager.set_call_ducked(true)
	DialogueManager.start_dialogue(MANAGER_OPENING, "Manager")
	await DialogueManager.dialogue_finished
	MusicManager.set_call_ducked(false)

	var should_skip: bool = await _show_skip_tutorial_prompt()
	if should_skip:
		skipped = true
		dialogBox.set_tab_feature_available(true)
		dialogBox.unlock_toggle_hud()
		return

	dialogBox.set_tab_feature_available(false)
	dialogBox.lock_toggle_hud()
	tool_walkthrough_active = true
	logbook_walkthrough_complete = false
	computer_walkthrough_complete = false
	_update_tool_quest()
	quest_panel.show()
	_refresh_quest_panel_layout()
	normal_lights.hide()
	logbook_light.show()
	pc_light.show()
	await tool_walkthrough_completed
	# Give the player a short breath before the first encounter rings.
	await get_tree().create_timer(1.75).timeout


func _on_any_phone_answered() -> void:
	opening_call_connected = true


func _show_skip_tutorial_prompt() -> bool:
	var prompt := PanelContainer.new()
	prompt.name = "SkipTutorialPrompt"
	prompt.z_index = 120
	prompt.set_anchors_preset(Control.PRESET_CENTER)
	prompt.position = Vector2(-300.0, -110.0)
	prompt.size = Vector2(600.0, 220.0)
	prompt.add_theme_stylebox_override("panel", _make_text_panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	prompt.add_child(column)
	var title := Label.new()
	title.text = "SKIP TUTORIAL?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", TUTORIAL_FONT)
	title.add_theme_font_size_override("font_size", 25)
	column.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	column.add_child(row)
	var skip_button := Button.new()
	skip_button.text = "SKIP"
	skip_button.custom_minimum_size = Vector2(210.0, 58.0)
	skip_button.pressed.connect(_select_skip_tutorial.bind(true))
	row.add_child(skip_button)
	var start_column := VBoxContainer.new()
	start_column.add_theme_constant_override("separation", 1)
	row.add_child(start_column)
	var start_button := Button.new()
	start_button.text = "START TUTORIAL"
	start_button.custom_minimum_size = Vector2(250.0, 58.0)
	start_button.pressed.connect(_select_skip_tutorial.bind(false))
	start_column.add_child(start_button)
	var recommended := Label.new()
	recommended.text = "RECOMMENDED"
	recommended.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recommended.add_theme_font_override("font", TUTORIAL_FONT)
	recommended.add_theme_font_size_override("font_size", 10)
	recommended.add_theme_color_override("font_color", TUTORIAL_ACCENT)
	start_column.add_child(recommended)
	tab_explanation.get_parent().add_child(prompt)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var result: bool = await skip_tutorial_selected
	prompt.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return result


func _select_skip_tutorial(should_skip: bool) -> void:
	skip_tutorial_selected.emit(should_skip)


func _on_walkthrough_logbook_clicked() -> void:
	_note_daniel_tool_activity()
	if arthur_tutorial_active:
		arthur_logbook_checked = true
		_update_arthur_quests()
		return
	if maya_tutorial_active:
		maya_logbook_checked = true
		_update_maya_quests()
		return
	if daniel_tutorial_active:
		_run_daniel_logbook_check()
		return
	if tracey_verification_active and not tracey_logbook_checked and not verification_dialogue_running:
		await _run_tracey_logbook_check()
		return
	if not tool_walkthrough_active or logbook_walkthrough_complete or tool_dialogue_running:
		return
	await _run_tool_dialogue(MANAGER_LOGBOOK, true)


func _on_walkthrough_computer_opened() -> void:
	_note_daniel_tool_activity()
	if arthur_tutorial_active:
		_run_arthur_computer_check()
		return
	if maya_tutorial_active:
		return
	if daniel_tutorial_active:
		_run_daniel_computer_check()
		return
	if tracey_verification_active and not tracey_computer_checked and not verification_dialogue_running:
		await _run_tracey_computer_check()
		return
	if not tool_walkthrough_active or computer_walkthrough_complete or tool_dialogue_running:
		return
	await _run_tool_dialogue(MANAGER_COMPUTER, false)


func _run_tool_dialogue(dialogue: DialogueNode, is_logbook: bool) -> void:
	tool_dialogue_running = true
	logBook.isLogbookClikable = false
	computah.clickable = false
	if is_logbook:
		loggBookUi.logBookClosable = false
	else:
		computahUi.set_roster_closable(false)
	MusicManager.set_call_ducked(true)
	DialogueManager.start_dialogue(dialogue, "Manager")
	await DialogueManager.dialogue_finished
	if is_logbook:
		clear_spotlight()
		loggBookUi.logBookClosable = true
	else:
		computahUi.set_roster_closable(true)
	MusicManager.set_call_ducked(false)
	if computahUi.visible or loggBookUi.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_logbook:
		logbook_walkthrough_complete = true
		logbook_light.hide()
	else:
		computer_walkthrough_complete = true
		pc_light.hide()
	tool_dialogue_running = false
	logBook.isLogbookClikable = true
	computah.clickable = true
	_update_tool_quest()


func _run_tracey_logbook_check() -> void:
	verification_dialogue_running = true
	loggBookUi.logBookClosable = false
	tutorial_allowed_actions = [&"Confirm"]
	verification_focus_generation += 1
	var focus_generation := verification_focus_generation
	_show_logbook_focus_after_delay(focus_generation)
	await dialogBox.play_tutorial_line(TRACEY_LOGBOOK_CHECK)
	verification_focus_generation += 1
	clear_spotlight()
	tutorial_allowed_actions.clear()
	loggBookUi.logBookClosable = true
	tracey_logbook_checked = true
	logbook_light.hide()
	verification_dialogue_running = false
	GameState.enter_desk_state()
	if loggBookUi.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_tracey_verification_quest()


func _show_logbook_focus_after_delay(generation: int) -> void:
	await get_tree().create_timer(0.4).timeout
	if not verification_dialogue_running or generation != verification_focus_generation:
		return
	world_dimmer.layer = 4
	show_spotlight([loggBookUi.right_page])


func _run_tracey_computer_check() -> void:
	verification_dialogue_running = true
	computahUi.set_roster_closable(false)
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(TRACEY_COMPUTER_CHECK)
	tutorial_allowed_actions.clear()
	computahUi.set_roster_closable(true)
	tracey_computer_checked = true
	pc_light.hide()
	verification_dialogue_running = false
	GameState.enter_desk_state()
	if computahUi.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_tracey_verification_quest()


func _update_tracey_verification_quest() -> void:
	var completed := int(tracey_logbook_checked) + int(tracey_computer_checked)
	quest_logbook.text = "[%d/2] Verify her against computer & logbook" % completed


func _run_tracey_verification() -> void:
	tracey_verification_active = true
	tracey_logbook_checked = false
	tracey_computer_checked = false
	_update_tracey_verification_quest()
	while not (tracey_logbook_checked and tracey_computer_checked):
		await get_tree().process_frame
	while loggBookUi.visible or computahUi.visible:
		await get_tree().process_frame
	tracey_verification_active = false
	normal_lights.show()
	quest_logbook.text = "[x] Verify her against computer & logbook"
	await _run_return_to_call_nudge(TRACEY_RETURN_NUDGE, 10.0)
	_show_tracey_final_quests()


func _run_return_to_call_nudge(line: DialogueNode, delay: float) -> void:
	var elapsed := 0.0
	while elapsed < delay and not dialogBox.is_hud_visible:
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	if dialogBox.is_hud_visible:
		return
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(line)
	tutorial_allowed_actions.clear()
	if not dialogBox.is_hud_visible:
		GameState.enter_desk_state()


func _show_tracey_final_quests() -> void:
	tracey_final_quests_active = true
	tracey_optional_question_done = false
	_set_quest_heading("CALL CHECKLIST")
	quest_logbook.text = "[ ] Ask another question (optional)"
	quest_computer.text = "[ ] Decide how to handle the call"
	quest_logbook.show()
	quest_computer.show()
	quest_decision.hide()
	quest_panel.show()
	_refresh_quest_panel_layout()


func _on_tracey_tutorial_choice(choice: String) -> void:
	if arthur_tutorial_active and GameState.day == 1 and GameState.encounter == 4:
		if choice == "ACCEPT" or choice == "REJECT":
			arthur_tutorial_active = false
			quest_decision.text = "[x] Decide how to handle the call"
			_hide_daniel_quests_after_delay()
		return
	if maya_tutorial_active and GameState.day == 1 and GameState.encounter == 3:
		if choice == "ACCEPT" or choice == "REJECT":
			maya_tutorial_active = false
			_dismiss_maya_guidance()
			quest_decision.text = "[x] Decide how to handle the visit"
			_hide_daniel_quests_after_delay()
		return
	if daniel_tutorial_active and GameState.day == 1 and GameState.encounter == 2:
		if choice == "ACCEPT" or choice == "REJECT":
			daniel_tutorial_active = false
			quest_decision.text = "[x] Decide how to handle the call"
			quest_decision.add_theme_color_override("font_color", TUTORIAL_TEXT)
			_hide_daniel_quests_after_delay()
		return
	if not tracey_final_quests_active or GameState.day != 1 or GameState.encounter != 1:
		return
	if choice == "QUESTION":
		tracey_optional_question_done = true
		quest_logbook.text = "[x] Ask another question (optional)"
	elif choice == "ACCEPT" or choice == "REJECT":
		tracey_final_quests_active = false
		quest_logbook.text = "[x] Ask another question (optional)"
		quest_computer.text = "[x] Decide how to handle the call"
		_hide_tracey_final_quests_after_delay()


func _hide_tracey_final_quests_after_delay() -> void:
	await get_tree().create_timer(0.55).timeout
	quest_panel.hide()


func _hide_daniel_quests_after_delay() -> void:
	await get_tree().create_timer(0.55).timeout
	quest_panel.hide()


func _on_tutorial_dialogue_started(node: DialogueNode) -> void:
	if not tool_walkthrough_active or not tool_dialogue_running:
		return
	if node == MANAGER_LOGBOOK:
		world_dimmer.layer = 4
		show_spotlight([loggBookUi.left_page])
	elif node == MANAGER_LOGBOOK.next_node:
		world_dimmer.layer = 4
		show_spotlight([loggBookUi.right_page])
	
#
func introduce_logbook():
	normal_lights.hide()
	#get_tree().paused = true
	logbook_light.show()
	#var label:Label=tab_explanation.get_node("introduceLogbook/PanelTexts/PanelContainer/Label").show()
	#label.text=""
	#panelTexts.show()
	instruction_hint = "CLICK THE HIGHLIGHTED LOGBOOK"
	pointer.point_at(logBook)
	await logBook.logbook_clicked
	instruction_hint = ""
	world_dimmer.show()
	logbook_light.hide()
	loggBookUi.logBookClosable=false
	pointer.hide_pointer()
	
	var logbookleft:Control=tab_explanation.get_node("logbookleft")
	logbookleft.show()
	await mouse_clicked
	logbookleft.hide()
	var logbookright:Control=tab_explanation.get_node("logbookright")	
	logbookright.show()
	await mouse_clicked
	logbookright.hide()
	
	loggBookUi.logBookClosable=true
	loggBookUi.close_logbook()
	
	logbook_light.hide()
	normal_lights.show()
	world_dimmer.hide()

	
	
	
	

func introduce_phone():
	normal_lights.hide()
	phone_light.show()
	logbook_light.hide()
	phone_tutorial.hide()
	MusicManager.set_call_ducked(true)
	DialogueManager.start_dialogue(TRACEY_PICKUP, "Manager")
	await DialogueManager.dialogue_finished
	await phone.call_answered
	phone_light.hide()
	normal_lights.show()
	
	
func introduce_tabs():
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()

	var dialogue_panel := dialogBox.get_node("DialoguePanel") as Control
	var decision_actions := accept_reject_buttons.accept.get_parent() as Control
	var question_action := accept_reject_buttons.question.get_parent() as Control
	# First reveal the complete call-management HUD before narrowing its focus.
	tutorial_allowed_actions = [&"Confirm"]
	clear_spotlight()
	await dialogBox.play_tutorial_line(TRACEY_HUD_OVERVIEW)

	world_dimmer.layer = 10
	tutorial_allowed_actions = [&"Confirm"]
	show_spotlight([decision_actions, dialogue_panel])
	await dialogBox.play_tutorial_line(TRACEY_ACCEPT_REJECT)

	# Shift the focus from the decision pair to the question control.
	await transition_spotlight(decision_actions, question_action, [dialogue_panel])
	await dialogBox.play_tutorial_line(TRACEY_QUESTIONS_INTRO)
	dialogBox.show_tutorial_action_prompt("Press Q to ask a question.")
	show_spotlight([question_action, dialogue_panel])
	tutorial_allowed_actions = [&"Question"]
	accept_reject_buttons.unlock_question()
	await accept_reject_buttons.sendqn
	tutorial_allowed_actions.clear()

func select_question():
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	# The first beat exists only so the player can read and browse all four
	# questions. Confirm must not leak through until the Manager points out the
	# reservation question explicitly.
	dialogBox.lock_confirm()

	world_dimmer.layer = 10
	show_spotlight([dialogBox.choices_container])
	tutorial_allowed_actions = [&"Move Up", &"Move Down"]
	await play_tutorial_notice(TRACEY_QUESTION_NAVIGATION)

	# Reservation is authored as the first question for Tracey.
	dialogBox.set_tutorial_choice_index(0)
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	var reservation_button := dialogBox.choices_container.get_child(0) as Control
	show_spotlight([reservation_button])
	tutorial_allowed_actions = [&"Confirm"]
	var reservation_tutorial := show_bounded_tutorial_dialogue(TRACEY_RESERVATION)
	dialogBox.unlock_confirm()
	await dialogBox.confirmqn
	await dismiss_tutorial_dialogue(reservation_tutorial)

	tutorial_allowed_actions.clear()
	clear_spotlight()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.lock_toggle_hud()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	should_check_tab = true

func check_tab_button():
	check_tab_button_active = true
	dialogBox.tutorial_check_tab_active = true
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()

	_show_verification_quest()
	await play_tutorial_notice(TRACEY_VERIFY)
	var tab_tutorial := show_bounded_tutorial_dialogue(TRACEY_TAB_INSTRUCTION)
	dialogBox.set_tab_feature_available(true)
	dialogBox.unlock_toggle_hud()
	world_dimmer.layer = 10
	show_spotlight([dialogBox.hint_label])
	tutorial_allowed_actions = [&"toggle_hud"]
	await dialogBox.tab_checked
	await dismiss_tutorial_dialogue(tab_tutorial)
	tutorial_allowed_actions.clear()
	clear_spotlight()
	check_tab_button_active = false
	should_check_tab = false
	dialogBox.tutorial_check_tab_active = false

	# The player can inspect either tool first. Progress is based on both UIs
	# actually being opened and their dedicated dialogue completing.
	await _run_tracey_verification()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.unlock_toggle_hud()

func check_computer_click():
	
	pointer.point_at(computah)

	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()
	dialogBox.lock_toggle_hud()

	await computah.computer_clicked
	pointer.hide_pointer()
	tab_explanation.get_node("itmatches").show()

	await computahUi.computah_closed

	if tab_explanation.has_node("itmatches"):
		tab_explanation.get_node("itmatches").hide()

	await get_tree().create_timer(0.25).timeout

	pointer.hide_pointer()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()
	quest_logbook.text = "[x] Verify her against computer & logbook"
	await get_tree().create_timer(0.35).timeout
	quest_panel.hide()
	logbook_light.hide()
	pc_light.hide()
	normal_lights.show()
	
	
func introduce_clock(choice: String):
	var clock_dialogue: DialogueNode = TRACEY_ACCEPTED_CLOCK if choice == "ACCEPT" else TRACEY_REJECTED_CLOCK
	clear_spotlight()
	world_dimmer.hide()
	normal_lights.hide()
	clock_light.show()
	camera.begin_cutscene_focus(clock, 1.35)
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(clock_dialogue)
	tutorial_allowed_actions.clear()
	await camera.end_cutscene_focus(0.65)
	clock_light.hide()
	normal_lights.show()
	
	
#ENCOUNTER 1 ENDED, NOW START 2
	
func enc2QuestionPointer():
	if daniel_intro_complete:
		return
	daniel_tutorial_active = true
	daniel_questions_asked.clear()
	daniel_logbook_checked = false
	daniel_resident_record_checked = false
	daniel_room_record_checked = false
	daniel_logbook_dialogue_shown = false
	daniel_computer_dialogue_shown = false
	daniel_last_tool_activity_msec = Time.get_ticks_msec()
	daniel_idle_nudge_played = false
	daniel_idle_desk_active = false
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_reject()
	_show_daniel_quests()
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(DANIEL_HISTORY_INTRO)
	await dialogBox.play_tutorial_line(DANIEL_FLOW_INTRO)
	tutorial_allowed_actions.clear()
	daniel_intro_complete = true
	dialogBox.unlock_toggle_hud()
	accept_reject_buttons.unlock_question()


func enc2SelectQuestion():
	if not daniel_tutorial_active:
		return
	for index in dialogBox.dialogue_choices.size():
		var button := dialogBox.choices_container.get_child(index) as DialogueChoiceButton
		var choice := dialogBox.dialogue_choices[index]
		button.set_recommended(_is_daniel_recommended_question(choice))
	_dismiss_daniel_recommendation()
	daniel_recommendation_entry = show_bounded_tutorial_dialogue(DANIEL_RECOMMENDED_QUESTIONS)
	_expire_daniel_recommendation(daniel_recommendation_entry)


func _expire_daniel_recommendation(entry: Dictionary) -> void:
	var hold_time := DANIEL_RECOMMENDED_QUESTIONS.duration
	var voice: AudioStream = DANIEL_RECOMMENDED_QUESTIONS.voiceline
	if voice != null:
		hold_time = maxf(hold_time, voice.get_length())
	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout
	if entry == daniel_recommendation_entry:
		daniel_recommendation_entry = {}
		_fade_floating_tutorial_dialogue(entry, 1.0)


func _dismiss_daniel_recommendation() -> void:
	if not daniel_recommendation_entry.is_empty():
		_fade_floating_tutorial_dialogue(daniel_recommendation_entry, 0.0)
		daniel_recommendation_entry = {}


func _is_daniel_recommended_question(choice: DialogueChoice) -> bool:
	return choice == DANIEL_QUESTION_CHECK_IN or choice == DANIEL_QUESTION_COMPANION


func can_select_dialogue_choice(choice: DialogueChoice) -> bool:
	if not daniel_tutorial_active or GameState.day != 1 or GameState.encounter != 2:
		return true
	return _is_daniel_recommended_question(choice)


func on_blocked_dialogue_choice() -> void:
	if not daniel_tutorial_active or daniel_interstitial_running:
		return
	if not daniel_warning_entry.is_empty():
		return
	daniel_warning_generation += 1
	var generation := daniel_warning_generation
	daniel_warning_entry = show_bounded_tutorial_dialogue(DANIEL_WRONG_QUESTION)
	_expire_daniel_warning(generation, daniel_warning_entry)


func _expire_daniel_warning(generation: int, entry: Dictionary) -> void:
	var hold_time := DANIEL_WRONG_QUESTION.duration
	var voice: AudioStream = DANIEL_WRONG_QUESTION.voiceline
	if voice != null:
		hold_time = maxf(hold_time, voice.get_length())
	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout
	if generation != daniel_warning_generation:
		return
	daniel_warning_entry = {}
	await _fade_floating_tutorial_dialogue(entry, 1.0)


func on_dialogue_choice_selected(choice: DialogueChoice) -> void:
	if daniel_tutorial_active and _is_daniel_recommended_question(choice):
		_dismiss_daniel_question_notices()
		if choice not in daniel_questions_asked:
			daniel_questions_asked.append(choice)
		_update_daniel_quests()
	elif maya_tutorial_active:
		_dismiss_maya_guidance()
		if (choice == MAYA_QUESTION_RELATIONSHIP or choice == MAYA_QUESTION_EXPECTED_TIME) \
			and choice not in maya_questions_asked:
			maya_questions_asked.append(choice)
		_update_maya_quests()
	elif arthur_tutorial_active:
		if choice not in arthur_questions_asked:
			arthur_questions_asked.append(choice)
		_update_arthur_quests()


func _dismiss_daniel_question_notices() -> void:
	daniel_warning_generation += 1
	if not daniel_warning_entry.is_empty():
		_fade_floating_tutorial_dialogue(daniel_warning_entry, 0.0)
		daniel_warning_entry = {}
	_dismiss_daniel_recommendation()


func _show_daniel_quests() -> void:
	_set_quest_heading("VERIFY DANIEL")
	quest_logbook.show()
	quest_computer.show()
	quest_decision.show()
	quest_panel.show()
	_refresh_quest_panel_layout()
	_update_daniel_quests()


func _update_daniel_quests() -> void:
	if not daniel_tutorial_active:
		return
	var questions_complete := daniel_questions_asked.size() >= 2
	var sources_complete := daniel_logbook_checked and daniel_resident_record_checked and daniel_room_record_checked
	quest_logbook.text = ("[x] " if questions_complete else "[ ] ") + "Ask the recommended questions"
	quest_computer.text = ("[x] " if sources_complete else "[ ] ") + "Verify details against both sources"
	quest_decision.text = "[ ] Decide how to handle the call"
	quest_decision.add_theme_color_override("font_color", TUTORIAL_TEXT if questions_complete and sources_complete else Color("65706f"))
	if questions_complete and sources_complete:
		accept_reject_buttons.unlock_accept()
		accept_reject_buttons.unlock_reject()
	else:
		accept_reject_buttons.lock_accept()
		accept_reject_buttons.lock_reject()


func _run_daniel_logbook_check() -> void:
	if daniel_logbook_dialogue_shown or daniel_interstitial_running:
		return
	daniel_logbook_dialogue_shown = true
	daniel_interstitial_running = true
	loggBookUi.logBookClosable = false
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(DANIEL_LOGBOOK_CHECK)
	tutorial_allowed_actions.clear()
	loggBookUi.logBookClosable = true
	daniel_logbook_checked = true
	daniel_interstitial_running = false
	GameState.enter_desk_state()
	if loggBookUi.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_daniel_quests()


func _run_daniel_computer_check() -> void:
	if daniel_computer_dialogue_shown or daniel_interstitial_running:
		return
	daniel_computer_dialogue_shown = true
	daniel_interstitial_running = true
	computahUi.set_roster_closable(false)
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(DANIEL_COMPUTER_CHECK)
	tutorial_allowed_actions.clear()
	computahUi.set_roster_closable(true)
	daniel_interstitial_running = false
	GameState.enter_desk_state()
	if computahUi.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_computer_record_selected(title: String, tab: String) -> void:
	_note_daniel_tool_activity()
	if daniel_tutorial_active and GameState.day == 1 and GameState.encounter == 2:
		if tab == "RESIDENTS" and title.to_upper() == "DANIEL REEVES":
			daniel_resident_record_checked = true
		elif tab == "ROOMS" and title.to_upper() == "ROOM 207":
			daniel_room_record_checked = true
		_update_daniel_quests()
	elif maya_tutorial_active and GameState.day == 1 and GameState.encounter == 3:
		if tab == "VISITORS" and title.to_upper() == "MAYA CHEN":
			maya_computer_record_checked = true
		_update_maya_quests()
	elif arthur_tutorial_active and GameState.day == 1 and GameState.encounter == 4:
		var normalized_title := title.to_upper()
		if (tab == "RESIDENTS" and normalized_title == "ARTHUR WILLIAMS") \
			or (tab == "ROOMS" and normalized_title == "ROOM 112"):
			arthur_record_checked = true
			_update_arthur_quests()
			if not arthur_sync_dialogue_shown and not arthur_interstitial_running:
				arthur_sync_dialogue_shown = true
				_play_arthur_sync_result()


func _note_daniel_tool_activity() -> void:
	if daniel_tutorial_active and GameState.day == 1 and GameState.encounter == 2:
		daniel_last_tool_activity_msec = Time.get_ticks_msec()


func _on_tutorial_tool_closed() -> void:
	_note_daniel_tool_activity()


func _update_daniel_idle_nudge() -> void:
	if not daniel_tutorial_active or daniel_idle_nudge_played or daniel_interstitial_running:
		return
	if not GameState.desk_state or dialogBox.history_open or loggBookUi.visible or computahUi.visible:
		daniel_idle_desk_active = false
		return
	if not daniel_idle_desk_active:
		daniel_idle_desk_active = true
		daniel_last_tool_activity_msec = Time.get_ticks_msec()
		return
	if Time.get_ticks_msec() - daniel_last_tool_activity_msec < 15000:
		return
	daniel_idle_nudge_played = true
	daniel_interstitial_running = true
	_play_daniel_idle_nudge()


func _play_daniel_idle_nudge() -> void:
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(DANIEL_RETURN_NUDGE)
	tutorial_allowed_actions.clear()
	daniel_interstitial_running = false


func _on_locked_decision_attempted(_choice: String) -> void:
	if not daniel_tutorial_active or daniel_interstitial_running:
		return
	daniel_interstitial_running = true
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(DANIEL_DECISION_BLOCKED)
	tutorial_allowed_actions.clear()
	daniel_interstitial_running = false


func e2_check_tab_button():
	world_dimmer.show()
	check_tab_button_active = true
	dialogBox.tutorial_check_tab_active = true
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()
	#dialogBox.lock_toggle_hud()
	
	tab_explanation.get_node("ENC2/checktab").show()
	await dialogBox.tab_checked
	tab_explanation.get_node("ENC2/checktab").hide()
	check_tab_button_active = false
	should_check_tab = false
	dialogBox.tutorial_check_tab_active = false
	
	# unlock only after the tutorial has actually observed the Tab press
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.lock_toggle_hud()
	world_dimmer.hide()
	check_logBook_click()
	
func check_logBook_click():
	
	pointer.point_at(logBook)

	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()
	dialogBox.lock_toggle_hud()

	await logBook.logbook_clicked
	tab_explanation.get_node("ENC2/becareful").show()
	world_dimmer.show()

	await loggBookUi.logbookClosed
	


	tab_explanation.get_node("ENC2/becareful").hide()

	await get_tree().create_timer(0.25).timeout

	pointer.hide_pointer()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()
	
func mayaChenIntroduction(mayaChen: Node3D) -> void:
	maya_tutorial_active = true
	maya_hud_initialized = false
	maya_question_guidance_shown = false
	maya_questions_asked.clear()
	maya_logbook_checked = false
	maya_computer_record_checked = false
	camera.begin_cutscene_focus_position(mayaChen.global_position + Vector3.UP * 2.15, 1.2)
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(MAYA_VISITOR_INTRO)
	tutorial_allowed_actions.clear()
	await camera.end_cutscene_focus(0.6)
	
	
func enc3QuestionPointer():
	maya_hud_initialized = true
	_show_maya_quests()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()


func enc3SelectQuestion():
	if maya_question_guidance_shown:
		return
	maya_question_guidance_shown = true
	maya_guidance_entry = show_bounded_tutorial_dialogue(MAYA_QUESTION_GUIDANCE)
	_expire_maya_guidance(maya_guidance_entry)


func _expire_maya_guidance(entry: Dictionary) -> void:
	var hold_time := MAYA_QUESTION_GUIDANCE.duration
	var voice: AudioStream = MAYA_QUESTION_GUIDANCE.voiceline
	if voice != null:
		hold_time = maxf(hold_time, voice.get_length())
	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout
	if entry == maya_guidance_entry:
		maya_guidance_entry = {}
		_fade_floating_tutorial_dialogue(entry, 1.0)


func _dismiss_maya_guidance() -> void:
	if not maya_guidance_entry.is_empty():
		_fade_floating_tutorial_dialogue(maya_guidance_entry, 0.0)
		maya_guidance_entry = {}


func _show_maya_quests() -> void:
	_set_quest_heading("VERIFY VISITOR")
	quest_logbook.show()
	quest_computer.show()
	quest_decision.show()
	quest_panel.show()
	_refresh_quest_panel_layout()
	_update_maya_quests()


func _update_maya_quests() -> void:
	if not maya_tutorial_active:
		return
	quest_logbook.text = ("[x] " if maya_questions_asked.size() >= 2 else "[ ] ") + "Ask the useful questions"
	quest_computer.text = ("[x] " if maya_logbook_checked and maya_computer_record_checked else "[ ] ") + "Verify details against both sources"
	quest_decision.text = "[ ] Decide how to handle the visit"
	quest_decision.add_theme_color_override("font_color", TUTORIAL_TEXT)


func _on_midnight_reached() -> void:
	if skipped or midnight_sync_shown or GameState.day != 1:
		return
	midnight_sync_shown = true
	midnight_sync_running = true
	TimeManager.pause()
	clear_spotlight()
	world_dimmer.hide()
	normal_lights.hide()
	clock_light.show()
	camera.begin_cutscene_focus(clock, 1.25)
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(MIDNIGHT_SYNC_INTRO)
	tutorial_allowed_actions.clear()
	await camera.end_cutscene_focus(0.6)
	clock_light.hide()
	normal_lights.show()
	midnight_sync_running = false
	TimeManager.resume_normal()


func initialize_arthur_tutorial() -> void:
	arthur_hud_initialized = true
	arthur_tutorial_active = true
	arthur_questions_asked.clear()
	arthur_logbook_checked = false
	arthur_record_checked = false
	arthur_computer_dialogue_shown = false
	arthur_sync_dialogue_shown = false
	arthur_interstitial_running = false
	_set_quest_heading("VERIFY ARTHUR")
	quest_logbook.show()
	quest_computer.show()
	quest_decision.show()
	quest_panel.show()
	_refresh_quest_panel_layout()
	_update_arthur_quests()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_cancel()


func _update_arthur_quests() -> void:
	if not arthur_tutorial_active:
		return
	quest_logbook.text = ("[x] " if arthur_questions_asked.size() >= 2 else "[ ] ") + "Ask 2 questions"
	quest_computer.text = ("[x] " if arthur_logbook_checked and arthur_record_checked else "[ ] ") + "Verify details against both sources"
	quest_decision.text = "[ ] Decide how to handle the call"
	quest_decision.add_theme_color_override("font_color", TUTORIAL_TEXT)


func _run_arthur_computer_check() -> void:
	if arthur_computer_dialogue_shown or arthur_interstitial_running:
		return
	arthur_computer_dialogue_shown = true
	arthur_interstitial_running = true
	computahUi.set_roster_closable(false)
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(ARTHUR_COMPUTER_CHECK)
	tutorial_allowed_actions.clear()
	computahUi.set_roster_closable(true)
	arthur_interstitial_running = false
	GameState.enter_desk_state()
	if computahUi.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _play_arthur_sync_result() -> void:
	arthur_interstitial_running = true
	computahUi.set_roster_closable(false)
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(ARTHUR_SYNC_RESULT)
	tutorial_allowed_actions.clear()
	computahUi.set_roster_closable(true)
	arthur_interstitial_running = false
	GameState.enter_desk_state()
	if computahUi.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_tutorial_computer_clicked() -> void:
	# Encounter 4 computer guidance is driven by the roster-opened and actual
	# record-selected signals, not by clicking the 3D monitor shell.
	return


func show_final_shift_tutorial() -> void:
	tutorial_allowed_actions = [&"Confirm"]
	await dialogBox.play_tutorial_line(FINAL_SHIFT_ONE)
	await dialogBox.play_tutorial_line(FINAL_SHIFT_TWO)
	tutorial_allowed_actions.clear()


func reset_after_secret_navigation() -> void:
	# Secret encounter navigation can interrupt a tutorial while it is awaiting
	# input. Restore every visual and interaction lock before loading the target.
	skipped = true
	set_process_input(false)
	world_dimmer.hide()
	normal_lights.show()
	phone_light.hide()
	logbook_light.hide()
	pc_light.hide()
	clock_light.hide()
	phone_tutorial.hide()
	tool_walkthrough_active = false
	tool_dialogue_running = false
	spotlight_targets.clear()
	tutorial_allowed_actions.clear()
	tracey_verification_active = false
	verification_dialogue_running = false
	tracey_final_quests_active = false
	if is_instance_valid(quest_panel):
		quest_panel.hide()
	pointer.hide_pointer()
	instruction_hint = ""
	check_tab_button_active = false
	should_check_tab = false
	dialogBox.tutorial_check_tab_active = false
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.unlock_toggle_hud()
	for child in tab_explanation.get_children():
		if child is CanvasItem:
			(child as CanvasItem).hide()
	
	
