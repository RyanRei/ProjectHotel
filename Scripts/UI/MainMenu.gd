class_name MainMenu
extends Control

const GAME_SCENE := "res://Scenes/hotelScene.tscn"
const DESIGN_SIZE := Vector2(1280.0, 720.0)

@onready var design_canvas: Control = %DesignCanvas
@onready var menu_buttons: Control = %MenuButtons
@onready var begin_button: Button = %BeginButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var options_panel: PanelContainer = %OptionsPanel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var back_button: Button = %BackButton


func _ready() -> void:
	MusicManager.play_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_fit_design_canvas()
	get_viewport().size_changed.connect(_fit_design_canvas)
	menu_buttons.show()
	options_panel.hide()

	begin_button.pressed.connect(_begin_shift)
	settings_button.pressed.connect(_open_options)
	quit_button.pressed.connect(_quit_game)
	volume_slider.value_changed.connect(_set_master_volume)
	fullscreen_toggle.toggled.connect(_set_fullscreen)
	back_button.pressed.connect(_close_options)
	for button in [begin_button, settings_button, quit_button]:
		button.mouse_entered.connect(button.grab_focus)
		button.gui_input.connect(_on_menu_button_gui_input.bind(button))

	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	begin_button.grab_focus()


func _fit_design_canvas() -> void:
	if design_canvas == null:
		return
	var viewport_size := get_viewport_rect().size
	var fit_scale := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	design_canvas.scale = Vector2.ONE * fit_scale
	design_canvas.position = (viewport_size - DESIGN_SIZE * fit_scale) * 0.5


func _on_menu_button_gui_input(event: InputEvent, button: Button) -> void:
	if event is InputEventMouseMotion:
		button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if options_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_options()
		get_viewport().set_input_as_handled()
		return
	if options_panel.visible:
		return
	if event.is_action_pressed("Move Up"):
		_focus_relative(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Move Down"):
		_focus_relative(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Confirm"):
		var focused := get_viewport().gui_get_focus_owner() as BaseButton
		if focused != null:
			focused.pressed.emit()
			get_viewport().set_input_as_handled()


func _focus_relative(direction: int) -> void:
	var buttons: Array[Button] = [begin_button, settings_button, quit_button]
	var focused := get_viewport().gui_get_focus_owner()
	var index := buttons.find(focused)
	if index < 0:
		index = 0
	else:
		index = wrapi(index + direction, 0, buttons.size())
	buttons[index].grab_focus()


func _begin_shift() -> void:
	GameState.day = 1
	GameState.encounter = 1
	GameState.reputation = 80.0
	GameState.share_price = 42.0
	GameState.story_flags.clear()
	GameState.enter_desk_state()
	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _open_options() -> void:
	menu_buttons.hide()
	options_panel.show()
	volume_slider.grab_focus()


func _close_options() -> void:
	options_panel.hide()
	menu_buttons.show()
	settings_button.grab_focus()


func _set_master_volume(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return
	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value / 100.0))


func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _quit_game() -> void:
	get_tree().quit()
