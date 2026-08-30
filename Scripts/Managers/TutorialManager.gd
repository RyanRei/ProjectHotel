class_name TutorialManager
extends Node

const TUTORIAL_FONT := preload("res://Assets/Fonts/ShareTechMono-Regular.ttf")
const TUTORIAL_TEXT := Color("dce8e3")
const TUTORIAL_ACCENT := Color("e6c968")
const TUTORIAL_BORDER := Color("526b70")
const TUTORIAL_PANEL := Color(0.012, 0.018, 0.021, 0.96)
const TUTORIAL_DIM := Color(0.004, 0.007, 0.009, 0.84)

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
var instruction_hint := ""
var encounter_four_update_shown := false

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
	if not computah.computer_clicked.is_connected(_on_tutorial_computer_clicked):
		computah.computer_clicked.connect(_on_tutorial_computer_clicked)


func _process(_delta: float) -> void:
	_update_continuation_hint()
	_update_spotlight_dimmer()


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
	style.border_color = TUTORIAL_ACCENT
	style.set_border_width_all(2)
	style.shadow_color = Color(TUTORIAL_ACCENT.r, TUTORIAL_ACCENT.g, TUTORIAL_ACCENT.b, 0.24)
	style.shadow_size = 5
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

	for index in range(4):
		var dimmer := ColorRect.new()
		dimmer.name = "SpotlightDimmer%d" % index
		dimmer.color = TUTORIAL_DIM
		dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_dimmer.add_child.call_deferred(dimmer)
		dimmer_panels.append(dimmer)


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
	if dimmer_panels.size() != 4 or not world_dimmer.visible:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var highlight := _find_visible_highlight(tab_explanation)
	if highlight == null:
		_set_dimmer_rects(Rect2(Vector2.ZERO, viewport_size), Rect2())
		return

	var cutout := highlight.get_global_rect().grow(5.0)
	cutout = cutout.intersection(Rect2(Vector2.ZERO, viewport_size))
	_set_dimmer_rects(Rect2(Vector2.ZERO, viewport_size), cutout)


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
	return bool(_get_prompt_input_rule().active)


func _get_prompt_input_rule() -> Dictionary:
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
	
	world_dimmer.show()
	get_tree().paused = true
	#var label:Label=dialog_tutorial.get_node("Panel/Label")
	
	var label= tab_explanation.get_node("opening/PanelContainer/Label")
	#dialog_tutorial.show()
	tab_explanation.get_node("opening").show()
	label.text="Six PM. Shift starts. You're the night operator for XXXXXX Co. 
	Access Cards may get lost or damaged. When that happens, there's exactly one way back into their rooms, and THAT is YOUR whole job. 
	"
	await mouse_clicked
	label.text="Your shift runs from 6 PM to 6 AM. Rooms close for check-out at 10 and, well, anyone calling in after that better have a very good reason
	"
	await mouse_clicked
	label.text="Every decision you make tonight gets read out tomorrow morning in the daily “xxxx”. If you let the wrong person in, the resident dies. Turn away the right person, they die too except just outside instead of in. Either way, the company's numbers move up and down. Enough bad mornings, and the shelter crashes to an end.
	So. Let's get you prepared for the first call"
	await mouse_clicked
	label.text="Lets take a look with help of a walkthrough"
	await mouse_clicked
	tab_explanation.get_node("opening").hide()
	get_tree().paused = false
	world_dimmer.hide()
	await introduce_logbook()
	
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
	#get_tree().paused = true
	phone_light.show()
	logbook_light.hide()
	#var label:Label=phone
	phone_tutorial.show()
	pointer.point_at(phone)
	
	await phone.call_answered
	phone_tutorial.hide()
	pointer.hide_pointer()
	
	phone_light.hide()
	normal_lights.show()
	
	
func introduce_tabs():
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	
	tab_explanation.get_node("acceptReject").show()
	
	await mouse_clicked
	tab_explanation.get_node("acceptReject").hide()
	tab_explanation.get_node("question").show()
	accept_reject_buttons.unlock_question()
	await accept_reject_buttons.sendqn
	tab_explanation.get_node("question").hide()

	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	#accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()

func select_question():
	
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	dialogBox.lock_move_down()
	dialogBox.lock_move_down()

	tab_explanation.get_node("q1tracey").show()
	await dialogBox.confirmqn
	tab_explanation.get_node("q1tracey").hide()
	
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	should_check_tab = true
	world_dimmer.hide()

func check_tab_button():
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
	
	tab_explanation.get_node("checktab").show()
	await dialogBox.tab_checked
	tab_explanation.get_node("checktab").hide()
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
	check_computer_click()

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
	
	
func introduce_clock():
	normal_lights.hide()
	clock_light.show()
	var clock_dialogue := tab_explanation.get_node("clockticks") as Control
	var clock_label := clock_dialogue.get_node("PanelContainer/Label") as Label
	clock_label.text = "Nice! The moment you hang up, the clock starts moving again. Get ready for the next ring at any time."
	clock_dialogue.show()
	pointer.point_at(clock)
	
	await mouse_clicked
	clock_dialogue.hide()
	pointer.hide_pointer()
	
	clock_light.hide()
	normal_lights.show()
	
	
#ENCOUNTER 1 ENDED, NOW START 2
	
func enc2QuestionPointer():
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	print("question")
	tab_explanation.get_node("ENC2/questionPointer").show()
	accept_reject_buttons.unlock_question()
	await accept_reject_buttons.sendqn
	tab_explanation.get_node("ENC2/questionPointer").hide()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	#accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()


func enc2SelectQuestion():
	
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()

	tab_explanation.get_node("ENC2/q1daniel").show()
	await dialogBox.confirmqn
	tab_explanation.get_node("ENC2/q1daniel").hide()
	
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	#should_check_tab = true
	world_dimmer.hide()


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
	
func mayaChenIntroduction(mayaChen):
	var maya_dialogue := tab_explanation.get_node("ENC3/mayaChenIntro") as Control
	var maya_label := maya_dialogue.get_node("PanelContainer/Label") as Label
	maya_label.text = "Not every call is a resident locked out of their own room. Sometimes it's someone asking to be let in to see someone else. Check the logbook first. Expected visitors get written down."
	maya_dialogue.show()
	pointer.point_at(mayaChen)
	await mouse_clicked
	maya_dialogue.hide()
	pointer.hide_pointer()
	
	
func enc3QuestionPointer():
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	
	tab_explanation.get_node("ENC3/questionPointer").show()
	accept_reject_buttons.unlock_question()
	await accept_reject_buttons.sendqn
	tab_explanation.get_node("ENC3/questionPointer").hide()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	#accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()


func enc3SelectQuestion():
	
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	#dialogBox.lock_move_up()
	#dialogBox.lock_move_down()

	tab_explanation.get_node("ENC3/q1maya").show()
	await dialogBox.confirmqn
	tab_explanation.get_node("ENC3/q1maya").hide()
	
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	#dialogBox.unlock_move_up()
	#dialogBox.unlock_move_down()
	#should_check_tab = true
	world_dimmer.hide()


func _on_tutorial_computer_clicked() -> void:
	if GameState.day != 1 or GameState.encounter != 4 or encounter_four_update_shown:
		return
	encounter_four_update_shown = true
	# Avoid consuming the same click that opened the computer.
	await get_tree().process_frame
	var update_dialogue := tab_explanation.get_node("clockticks") as Control
	var update_label := update_dialogue.get_node("PanelContainer/Label") as Label
	update_label.text = "See that? His entry is mid-update. The system genuinely doesn't know right now. This is exactly when the logbook saves you."
	update_dialogue.show()
	await mouse_clicked
	update_dialogue.hide()


func show_final_shift_tutorial() -> void:
	var final_dialogue := tab_explanation.get_node("clockticks") as Control
	var final_label := final_dialogue.get_node("PanelContainer/Label") as Label
	world_dimmer.show()
	final_dialogue.show()
	final_label.text = "That's the shift, start to finish. Nobody's going to hold your hand after this."
	await mouse_clicked
	final_label.text = "Good luck. And remember, TRUST NO ONE."
	await mouse_clicked
	final_dialogue.hide()
	world_dimmer.hide()
	
	
