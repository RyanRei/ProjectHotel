class_name LogbookUI
extends Control

const PageCurlScript = preload("res://Scripts/Logbook/PageCurl2D.gd")
const StickyTabScript = preload("res://Scripts/Logbook/StickyBookmarkButton.gd")
const BINDER_TEXTURE = preload("res://Assets/UI/Logbook/logbook_open_binder.png")

const INK := Color("332b23")
const MUTED_INK := Color("6f6354")
const PAPER := Color("d8c7a2")
const PAPER_DARK := Color("bea980")
const COVER := Color("3b2b22")
const TAB_COLORS := [Color("a95445"), Color("b58439"), Color("6f8150"), Color("4f777a")]

var pages: Array[Dictionary] = [
	{"tab":"SHIFT", "title":"SHIFT 1  •  AUGUST 26", "subtitle":"6:00 PM — 6:00 AM", "entries":[["6:00 PM","Shift opened. Roster last synchronized at 5:45 PM."],["7:40 PM","Tracey Miller, Room 101, pre-authorized visitor Maya Chen."],["9:00 PM","Room 102 checkout deadline. Sennet Cole no longer has active access."],["12:00 AM","Roster update window begins. Confirm conflicting records here."]]},
	{"tab":"VISITORS", "title":"EXPECTED VISITORS", "subtitle":"Verify ID and arrival window", "entries":[["8:30–9:15","Maya Chen → Tracey Miller, Room 101. License ending 6621."],["10:15–11:00","Clara Hayes → William Hayes, Room 103. National ID ending 4408."],["11:30–12:00","Daniel Ortiz → Nina Patel, Room 104. Passport ending 9184."],["IMPORTANT","A matching name alone is not proof. Confirm the host and one fixed detail."]]},
	{"tab":"RESIDENTS", "title":"RESIDENT NOTES", "subtitle":"Special requirements and exceptions", "entries":[["ROOM 101","Tracey Miller. Phone ending 7734. Visitor call recorded at 7:40 PM."],["ROOM 103","William Hayes has impaired hearing. Repeat questions clearly; allow extra time."],["ROOM 104","Nina Patel. Phone ending 1183. Daniel Ortiz expected before midnight."],["ROOM 107","Marcus Reed is away and expects to return after midnight."]]},
	{"tab":"INCIDENTS", "title":"INCIDENTS & MAINTENANCE", "subtitle":"Record anything unusual", "entries":[["6:25 PM","Lobby camera briefly lost signal. Restored at 6:31 PM."],["7:05 PM","Room 102 checkout recorded; cleaning inspection still pending."],["8:05 PM","Unknown person claimed Room 102 access. Entry denied."],["NOTICE","No maintenance staff are scheduled after 10:00 PM."]]},
]

var current_page := 0
var turning := false
var left_tabs: VBoxContainer
var right_tabs: VBoxContainer
var page_surface: PanelContainer
var title_label: Label
var subtitle_label: Label
var left_entries: VBoxContainer
var right_entries: VBoxContainer
var page_number: Label
var left_page: PanelContainer
var right_page: PanelContainer
var turning_page: PanelContainer
var page_curl: Control
var book_spine: ColorRect
var curl_layer: Control
var tab_layer: Control

func _ready() -> void:
	add_to_group("logbook_ui")
	add_to_group("desk_ui")
	build_interface()
	show_page(0)
	visible = false

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_logbook()
		get_viewport().set_input_as_handled()

func open_logbook() -> void:
	visible = true
	move_to_front()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_logbook() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.025, 0.02, 0.016, 0.80)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var layout := AspectRatioContainer.new()
	layout.ratio = 1.5
	layout.stretch_mode = AspectRatioContainer.STRETCH_FIT
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 34)
	add_child(layout)
	left_tabs = VBoxContainer.new()
	left_tabs.custom_minimum_size.x = 116
	left_tabs.add_theme_constant_override("separation", 7)
	page_surface = PanelContainer.new()
	page_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_surface.add_theme_stylebox_override("panel", make_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0))
	layout.add_child(page_surface)
	var binder_art := TextureRect.new()
	binder_art.name = "LeatherBinderArtwork"
	binder_art.texture = BINDER_TEXTURE
	binder_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	binder_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	binder_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_surface.add_child(binder_art)
	var book_margin := MarginContainer.new()
	book_margin.add_theme_constant_override("margin_left", 70)
	book_margin.add_theme_constant_override("margin_right", 70)
	book_margin.add_theme_constant_override("margin_top", 54)
	book_margin.add_theme_constant_override("margin_bottom", 54)
	page_surface.add_child(book_margin)
	var open_pages := HBoxContainer.new()
	open_pages.add_theme_constant_override("separation", 8)
	book_margin.add_child(open_pages)
	left_page = PanelContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.clip_contents = true
	left_page.add_theme_stylebox_override("panel", make_page_style(true))
	open_pages.add_child(left_page)
	var left_layout := VBoxContainer.new()
	left_layout.add_theme_constant_override("separation", 12)
	left_page.add_child(left_layout)
	var header := HBoxContainer.new()
	left_layout.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	title_label = make_label("", 20, INK)
	heading.add_child(title_label)
	subtitle_label = make_label("", 13, MUTED_INK)
	heading.add_child(subtitle_label)
	left_layout.add_child(HSeparator.new())
	left_entries = VBoxContainer.new()
	left_entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_entries.add_theme_constant_override("separation", 10)
	left_layout.add_child(left_entries)
	book_spine = ColorRect.new()
	book_spine.color = Color(0.12, 0.075, 0.04, 0.50)
	book_spine.custom_minimum_size.x = 14
	book_spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	open_pages.add_child(book_spine)
	right_page = PanelContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.clip_contents = true
	right_page.add_theme_stylebox_override("panel", make_page_style(false))
	open_pages.add_child(right_page)
	var right_layout := VBoxContainer.new()
	right_layout.add_theme_constant_override("separation", 12)
	right_page.add_child(right_layout)
	var right_header := HBoxContainer.new()
	right_layout.add_child(right_header)
	var daily_log := make_label("DAILY LOG  •  CONTINUED", 13, MUTED_INK)
	daily_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_header.add_child(daily_log)
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(100, 40)
	close_button.pressed.connect(close_logbook)
	right_header.add_child(close_button)
	right_layout.add_child(HSeparator.new())
	right_entries = VBoxContainer.new()
	right_entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_entries.add_theme_constant_override("separation", 10)
	right_layout.add_child(right_entries)
	page_number = make_label("", 14, MUTED_INK)
	page_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_layout.add_child(page_number)
	turning_page = PanelContainer.new()
	turning_page.visible = false
	turning_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turning_page.add_theme_stylebox_override("panel", make_turning_style())
	page_surface.add_child(turning_page)
	curl_layer = Control.new()
	curl_layer.name = "PageTurnOverlayLayer"
	curl_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curl_layer.clip_contents = false
	page_surface.add_child(curl_layer)
	page_curl = PageCurlScript.new()
	page_curl.name = "PageCurl2D"
	page_curl.visible = false
	curl_layer.add_child(page_curl)
	tab_layer = Control.new()
	tab_layer.name = "StickyBookmarkLayer"
	tab_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_layer.clip_contents = false
	page_surface.add_child(tab_layer)
	left_tabs.anchor_left = 0.0
	left_tabs.anchor_right = 0.0
	left_tabs.anchor_top = 0.18
	left_tabs.anchor_bottom = 0.18
	left_tabs.offset_left = -24
	left_tabs.offset_right = 80
	left_tabs.offset_top = 0
	left_tabs.offset_bottom = 0
	tab_layer.add_child(left_tabs)
	right_tabs = VBoxContainer.new()
	right_tabs.custom_minimum_size.x = 116
	right_tabs.add_theme_constant_override("separation", 7)
	right_tabs.anchor_left = 1.0
	right_tabs.anchor_right = 1.0
	right_tabs.anchor_top = 0.18
	right_tabs.anchor_bottom = 0.18
	right_tabs.offset_left = -80
	right_tabs.offset_right = 24
	right_tabs.offset_top = 0
	right_tabs.offset_bottom = 0
	tab_layer.add_child(right_tabs)

func turn_to_page(index: int) -> void:
	if turning or index == current_page:
		return
	turning = true
	var forward := index > current_page
	var source_page: Control = right_page if forward else left_page
	var spine_x := book_spine.global_position.x + book_spine.size.x * 0.5
	page_curl.position = Vector2(
		spine_x - curl_layer.global_position.x,
		source_page.global_position.y - curl_layer.global_position.y
	)
	page_curl.size = source_page.size
	page_curl.begin(forward)
	var first_half := create_tween()
	first_half.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	first_half.tween_property(page_curl, "progress", 0.5, 0.62)
	await first_half.finished
	show_page(index)
	var second_half := create_tween()
	second_half.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	second_half.tween_property(page_curl, "progress", 1.0, 0.62)
	await second_half.finished
	page_curl.visible = false
	turning = false

func configure_turning_page(target_page: Control, starts_open: bool) -> void:
	turning_page.position = target_page.global_position - page_surface.global_position
	turning_page.size = target_page.size
	turning_page.pivot_offset = Vector2(0, target_page.size.y * 0.5) if starts_open else Vector2(target_page.size.x, target_page.size.y * 0.5)
	turning_page.scale = Vector2(1.0 if starts_open else 0.035, 1.0)
	turning_page.rotation = 0.0 if starts_open else 0.035

func finish_page_turn() -> void:
	turning_page.visible = false
	turning = false

func show_page(index: int) -> void:
	current_page = clampi(index, 0, pages.size() - 1)
	var page := pages[current_page]
	title_label.text = str(page.title)
	subtitle_label.text = str(page.subtitle)
	for container in [left_entries, right_entries]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	for entry_index in page.entries.size():
		var entry = page.entries[entry_index]
		var row := PanelContainer.new()
		row.clip_contents = true
		row.add_theme_stylebox_override("panel", make_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 8))
		var row_layout := HBoxContainer.new()
		row_layout.add_theme_constant_override("separation", 18)
		row.add_child(row_layout)
		var time_label := make_label(str(entry[0]), 12, INK)
		time_label.custom_minimum_size.x = 82
		row_layout.add_child(time_label)
		var note_label := make_label(str(entry[1]), 13, INK)
		note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_layout.add_child(note_label)
		(left_entries if entry_index < 2 else right_entries).add_child(row)
	page_number.text = "—  %d / %d  —" % [current_page + 1, pages.size()]
	rebuild_tabs()

func rebuild_tabs() -> void:
	for container in [left_tabs, right_tabs]:
		for child in container.get_children(): child.queue_free()
	for index in pages.size():
		if index == current_page:
			continue
		var tab := StickyTabScript.new() as Button
		tab.text = "%d\n%s" % [index + 1, str(pages[index].tab).replace(" ", "\n")]
		tab.custom_minimum_size = Vector2(104, 58)
		tab.pressed.connect(turn_to_page.bind(index))
		var destination := left_tabs if index < current_page else right_tabs
		tab.call("configure", TAB_COLORS[index], destination == left_tabs)
		destination.add_child(tab)
		tab.rotation = deg_to_rad(-0.7 if destination == left_tabs else 0.7)
		tab.pivot_offset = tab.custom_minimum_size * 0.5

func make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func make_style(fill: Color, border: Color, border_width: int, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

func make_page_style(is_left: bool) -> StyleBoxFlat:
	var style := make_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 20)
	style.corner_radius_top_right = 1 if is_left else 5
	style.corner_radius_bottom_right = 1 if is_left else 5
	style.corner_radius_top_left = 5 if is_left else 1
	style.corner_radius_bottom_left = 5 if is_left else 1
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	return style

func make_turning_style() -> StyleBoxFlat:
	var style := make_style(Color("e1d1ad"), PAPER_DARK, 1, 4, 18)
	style.shadow_color = Color(0.04, 0.025, 0.015, 0.72)
	style.shadow_size = 18
	style.shadow_offset = Vector2(-12, 5)
	return style
