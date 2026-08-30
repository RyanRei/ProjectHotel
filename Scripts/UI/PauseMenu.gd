class_name PauseMenu
extends Control

const MAIN_MENU_SCENE := "res://Scenes/main_menu.tscn"

@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	hide()
	continue_button.pressed.connect(resume_game)
	main_menu_button.pressed.connect(return_to_main_menu)
	for button in [continue_button, main_menu_button]:
		button.mouse_entered.connect(button.grab_focus)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()
		return

	if not visible:
		return

	if event.is_action_pressed("Move Up") or event.is_action_pressed("Move Down"):
		var target := main_menu_button if continue_button.has_focus() else continue_button
		target.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Confirm"):
		var focused := get_viewport().gui_get_focus_owner() as BaseButton
		if focused != null and focused in [continue_button, main_menu_button]:
			focused.pressed.emit()
			get_viewport().set_input_as_handled()


func pause_game() -> void:
	if visible:
		return
	show()
	move_to_front()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_button.grab_focus()


func resume_game() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func return_to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.enter_desk_state()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

