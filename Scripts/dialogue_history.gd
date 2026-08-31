class_name DialogueHistory
extends PanelContainer

enum EntryType {
	GUEST,
	PLAYER,
	DECISION,
}

const HUD_FONT := preload("res://Assets/Fonts/ShareTechMono-Regular.ttf")
const GOLD := Color(1.0, 0.93, 0.61, 1.0)
const MUTED := Color(0.56, 0.64, 0.65, 1.0)
const GUEST_TEXT := Color(0.91, 0.94, 0.93, 1.0)
const PLAYER_TEXT := Color(0.97, 0.95, 0.84, 1.0)

@onready var shift_label: Label = $Margin/Layout/Header/ShiftLabel
@onready var entries: VBoxContainer = $Margin/Layout/Scroll/Entries
@onready var scroll: ScrollContainer = $Margin/Layout/Scroll
@onready var empty_label: Label = $Margin/Layout/Scroll/Entries/EmptyLabel

var recorded_shift := -1
var recorded_encounter := -1


func _ready() -> void:
	set_shift(GameState.day)


func set_shift(shift_number: int) -> void:
	if recorded_shift == shift_number:
		return
	recorded_shift = shift_number
	recorded_encounter = -1
	for child in entries.get_children():
		if child != empty_label:
			child.queue_free()
	empty_label.show()
	shift_label.text = "SHIFT %d" % shift_number


func add_guest_message(speaker_name: String, message: String) -> void:
	# Manager guidance is tutorial narration, not part of the resident/visitor
	# communication record the player consults during a call.
	if speaker_name.strip_edges().to_lower() == "manager":
		return
	_ensure_current_shift()
	if recorded_encounter != GameState.encounter:
		recorded_encounter = GameState.encounter
		_add_encounter_separator(speaker_name)
	_add_message(EntryType.GUEST, speaker_name if not speaker_name.is_empty() else "GUEST", message)


func add_player_message(message: String) -> void:
	_ensure_current_shift()
	_add_message(EntryType.PLAYER, "YOU", message)


func add_decision(decision: String) -> void:
	_ensure_current_shift()
	var label := "ACCESS GRANTED" if decision == "ACCEPT" else "ACCESS DENIED"
	var event := Label.new()
	event.text = "—  %s  ·  %s  —" % [label, TimeManager.get_time_string()]
	event.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event.add_theme_font_override("font", HUD_FONT)
	event.add_theme_font_size_override("font_size", 17)
	event.add_theme_color_override("font_color", GOLD)
	event.add_theme_constant_override("outline_size", 3)
	event.add_theme_color_override("font_outline_color", Color(0.008, 0.011, 0.014, 0.9))
	entries.add_child(event)
	_finish_entry_added()


func scroll_to_latest() -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func scroll_by(amount: int) -> void:
	var bar := scroll.get_v_scroll_bar()
	scroll.scroll_vertical = clampi(scroll.scroll_vertical + amount, 0, int(bar.max_value))


func _ensure_current_shift() -> void:
	if recorded_shift != GameState.day:
		set_shift(GameState.day)


func _add_encounter_separator(speaker_name: String) -> void:
	var separator := HBoxContainer.new()
	separator.add_theme_constant_override("separation", 12)

	var left_rule := HSeparator.new()
	left_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separator.add_child(left_rule)

	var title := Label.new()
	title.text = "%s  ·  %s" % [TimeManager.get_time_string(), speaker_name.to_upper() if not speaker_name.is_empty() else "GUEST"]
	title.add_theme_font_override("font", HUD_FONT)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", MUTED)
	separator.add_child(title)

	var right_rule := HSeparator.new()
	right_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separator.add_child(right_rule)

	entries.add_child(separator)


func _add_message(entry_type: int, speaker_name: String, message: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var message_column := VBoxContainer.new()
	message_column.custom_minimum_size = Vector2(560.0, 0.0)
	message_column.add_theme_constant_override("separation", 5)

	var metadata := Label.new()
	metadata.text = "%s   %s" % [speaker_name.to_upper(), TimeManager.get_time_string()]
	metadata.add_theme_font_override("font", HUD_FONT)
	metadata.add_theme_font_size_override("font_size", 16)
	metadata.add_theme_color_override("font_color", GOLD if entry_type == EntryType.GUEST else MUTED)
	metadata.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if entry_type == EntryType.PLAYER else HORIZONTAL_ALIGNMENT_LEFT
	message_column.add_child(metadata)

	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _make_message_style(entry_type))

	var message_label := Label.new()
	message_label.text = message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_override("font", HUD_FONT)
	message_label.add_theme_font_size_override("font_size", 21)
	message_label.add_theme_color_override("font_color", PLAYER_TEXT if entry_type == EntryType.PLAYER else GUEST_TEXT)
	bubble.add_child(message_label)
	message_column.add_child(bubble)

	if entry_type == EntryType.PLAYER:
		row.add_child(spacer)
		row.add_child(message_column)
		message_column.size_flags_horizontal = Control.SIZE_SHRINK_END
	else:
		row.add_child(message_column)
		row.add_child(spacer)
		message_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	entries.add_child(row)
	_finish_entry_added()


func _make_message_style(entry_type: EntryType) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.033, 0.038, 0.97) if entry_type == EntryType.GUEST else Color(0.055, 0.052, 0.038, 0.97)
	style.content_margin_left = 18.0
	style.content_margin_top = 12.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 12.0
	style.border_color = Color(0.34, 0.42, 0.43, 0.9) if entry_type == EntryType.GUEST else Color(0.72, 0.65, 0.38, 0.9)
	if entry_type == EntryType.GUEST:
		style.border_width_left = 3
		style.border_width_top = 1
		style.border_width_bottom = 1
	else:
		style.border_width_right = 3
		style.border_width_top = 1
		style.border_width_bottom = 1
	return style


func _finish_entry_added() -> void:
	empty_label.hide()
	if visible:
		scroll_to_latest()
