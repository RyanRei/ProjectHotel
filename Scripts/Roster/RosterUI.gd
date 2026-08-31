class_name RosterUI
extends Control

const COLOR_BACKGROUND := Color("10171a")
const COLOR_PANEL := Color("172125")
const COLOR_BORDER := Color("59615b")
const COLOR_TEXT := Color("ddd1b2")
const COLOR_MUTED := Color("8e9388")
const COLOR_AMBER := Color("a87329")
const COLOR_GREEN := Color("758e55")
const COLOR_YELLOW := Color("b18b37")
const COLOR_GRAY := Color("747b7a")
signal computah_closed
@export var pcClick:AudioStreamPlayer

var database := RosterDatabase.new()
var current_tab := "RESIDENTS"
var filtered_records: Array[Dictionary] = []
var tab_buttons: Dictionary = {}

var search_field: LineEdit
var roster_list: ItemList
var record_title: Label
var record_details: RichTextLabel
var status_label: Label
var sync_window_active := false


func _ready() -> void:
	add_to_group("roster_ui")
	add_to_group("desk_ui")
	set_process_input(true)
	build_interface()
	refresh_records("")
	visible = false
	sync_window_active = database.is_sync_window()
	TimeManager.time_updated.connect(_on_time_updated)


func _on_time_updated(_hour: int, _minute: int) -> void:
	var is_now_syncing := database.is_sync_window()
	if is_now_syncing == sync_window_active:
		return
	sync_window_active = is_now_syncing
	if visible and (current_tab == "ROOMS" or current_tab == "RESIDENTS"):
		refresh_records(search_field.text)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_roster()
		get_viewport().set_input_as_handled()


func open_roster() -> void:
	pcClick.play()
	visible = true
	move_to_front()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	search_field.grab_focus()
	refresh_records(search_field.text)


func close_roster() -> void:
	pcClick.play()
	computah_closed.emit()
	visible = false
	search_field.release_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.02, 0.025, 0.025, 0.72)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var monitor := PanelContainer.new()
	monitor.name = "RosterMonitor"
	monitor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 36)
	monitor.add_theme_stylebox_override("panel", make_style(COLOR_BACKGROUND, COLOR_BORDER, 3, 8))
	add_child(monitor)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	monitor.add_child(root)

	root.add_child(build_header())
	root.add_child(build_tabs())
	root.add_child(build_search())
	root.add_child(build_content())
	root.add_child(build_footer())


func build_header() -> Control:
	var row := HBoxContainer.new()
	var title := make_label("NIGHTHAVEN SHELTER SYSTEM", 24, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(make_label("11:45 PM", 22, COLOR_TEXT))
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(100, 36)
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.pressed.connect(close_roster)
	row.add_child(close_button)
	return row


func build_tabs() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for tab_name in ["RESIDENTS", "VISITORS", "ROOMS"]:#, "ACCESS LOG"]:
		var button := Button.new()
		button.text = tab_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", COLOR_TEXT)
		button.add_theme_stylebox_override("normal", make_style(COLOR_AMBER if tab_name == current_tab else COLOR_PANEL, COLOR_BORDER, 2, 3))
		button.pressed.connect(switch_tab.bind(tab_name))
		tab_buttons[tab_name] = button
		row.add_child(button)
	return row


func build_search() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	search_field = LineEdit.new()
	search_field.placeholder_text = "SEARCH NAME / ROOM / STATUS"
	search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_field.custom_minimum_size.y = 42
	search_field.add_theme_font_size_override("font_size", 17)
	search_field.add_theme_color_override("font_color", COLOR_TEXT)
	search_field.add_theme_color_override("font_placeholder_color", COLOR_MUTED)
	search_field.add_theme_stylebox_override("normal", make_style(Color("0d1316"), COLOR_BORDER, 2, 2))
	search_field.text_changed.connect(refresh_records)
	search_field.text_submitted.connect(func(_query: String) -> void: select_first_result())
	row.add_child(search_field)

	var clear_button := Button.new()
	clear_button.text = "CLEAR"
	clear_button.custom_minimum_size = Vector2(110, 42)
	clear_button.add_theme_font_size_override("font_size", 16)
	clear_button.pressed.connect(func() -> void: search_field.clear(); refresh_records(""))
	row.add_child(clear_button)
	return row


func build_content() -> Control:
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 680

	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", make_style(COLOR_PANEL, COLOR_BORDER, 2, 3))
	roster_list = ItemList.new()
	roster_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_list.add_theme_font_size_override("font_size", 18)
	roster_list.add_theme_color_override("font_color", COLOR_TEXT)
	roster_list.add_theme_color_override("font_selected_color", Color("fff0c7"))
	roster_list.add_theme_stylebox_override("selected", make_style(COLOR_AMBER, COLOR_AMBER, 0, 1))
	roster_list.item_selected.connect(show_selected_record)
	list_panel.add_child(roster_list)
	split.add_child(list_panel)

	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size.x = 430
	detail_panel.add_theme_stylebox_override("panel", make_style(COLOR_PANEL, COLOR_BORDER, 2, 3))
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 12)
	detail_panel.add_child(details)
	record_title = make_label("RESIDENT RECORD", 22, COLOR_TEXT)
	details.add_child(record_title)
	record_details = RichTextLabel.new()
	record_details.bbcode_enabled = true
	record_details.fit_content = false
	record_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	record_details.add_theme_font_size_override("normal_font_size", 18)
	record_details.add_theme_color_override("default_color", COLOR_TEXT)
	details.add_child(record_details)
	status_label = make_label("NO RECORD SELECTED", 17, COLOR_MUTED)
	details.add_child(status_label)
	split.add_child(detail_panel)
	return split


func build_footer() -> Control:
	var footer := make_label("SYSTEM ONLINE  •  RECORDS LAST UPDATED 11:30 PM  •  ESC TO CLOSE", 15, COLOR_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return footer


func switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	for name in tab_buttons:
		var button := tab_buttons[name] as Button
		button.add_theme_stylebox_override("normal", make_style(COLOR_AMBER if name == current_tab else COLOR_PANEL, COLOR_BORDER, 2, 3))
	search_field.placeholder_text = "SEARCH " + current_tab + " RECORDS"
	search_field.clear()
	refresh_records("")


func refresh_records(query: String) -> void:
	filtered_records = database.search_records(current_tab, query)
	roster_list.clear()
	for record in filtered_records:
		roster_list.add_item(str(record.summary))
	if filtered_records.is_empty():
		clear_record("NO MATCHING RECORDS")
	else:
		roster_list.select(0)
		show_selected_record(0)


func select_first_result() -> void:
	if not filtered_records.is_empty():
		roster_list.select(0)
		show_selected_record(0)


func show_selected_record(index: int) -> void:
	if index < 0 or index >= filtered_records.size():
		return
	var record := filtered_records[index]
	record_title.text = str(record.title)
	var details_text := "[table=2]"
	for field in record.fields:
		details_text += "[cell]" + str(field[0]).to_upper() + "[/cell][cell]" + str(field[1]).to_upper() + "[/cell]"
	record_details.text = details_text + "[/table]"
	status_label.text = "STATUS  •  " + str(record.status).to_upper()
	status_label.add_theme_color_override("font_color", status_color(str(record.status)))


func clear_record(message: String) -> void:
	record_title.text = current_tab.trim_suffix("S") + " RECORD"
	record_details.text = ""
	status_label.text = message
	status_label.add_theme_color_override("font_color", COLOR_MUTED)


func status_color(status: String) -> Color:
	match status.to_lower():
		"occupied", "approved", "granted", "recorded":
			return COLOR_GREEN
		"away", "pending", "expected", "in sync":
			return COLOR_YELLOW
		_:
			return COLOR_GRAY


func make_label(label_text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func make_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
