
class_name LogbookUI
extends Control

const PageCurlScript = preload("res://Scripts/Logbook/PageCurl2D.gd")
const StickyTabScript = preload("res://Scripts/Logbook/StickyBookmarkButton.gd")
const BINDER_TEXTURE = preload("res://Assets/UI/Logbook/logbook_open_binder.png")

const INK := Color("332b23")
const MUTED_INK := Color("6f6354")
const PAPER_DARK := Color("bea980")
const TAB_COLORS := [
	Color("d2a23f"),
	Color("9eb7bf"),
	Color("cf8078"),
	Color("a5a95d"),
	Color("c97b3d")
]

var pages: Array[Dictionary] = [
		{
		"tab":"VISITORS",
		"title":"EXPECTED VISITORS",
		"subtitle":"Day 1",

		"columns":["TIME","VISITOR"],
		"rows":[
		],

		#"details":"Only visitors recorded by a resident may enter. A matching name by itself is not proof.",


		"notes":""
	}
]

var current_page := 0
var turning := false

var left_tabs: Control
var right_tabs: Control
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
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close_logbook()
		get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed \
		and not is_point_over_book(event.position):

		close_logbook()
		get_viewport().set_input_as_handled()


func is_point_over_book(screen_position: Vector2) -> bool:
	if page_surface == null:
		return false

	return page_surface.get_global_rect().grow(20.0).has_point(screen_position)


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
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(_on_background_input)
	add_child(dimmer)

	var layout := AspectRatioContainer.new()
	layout.ratio = 1.5
	layout.stretch_mode = AspectRatioContainer.STRETCH_FIT
	layout.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_MINSIZE,
		34
	)
	add_child(layout)

	page_surface = PanelContainer.new()
	page_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_surface.add_theme_stylebox_override(
		"panel",
		make_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0)
	)

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
	open_pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_margin.add_child(open_pages)

	left_page = PanelContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_page.clip_contents = true
	left_page.add_theme_stylebox_override("panel", make_page_style(true))
	open_pages.add_child(left_page)

	var left_padding := MarginContainer.new()
	add_page_margins(left_padding)
	left_page.add_child(left_padding)

	var left_layout := VBoxContainer.new()
	left_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_layout.add_theme_constant_override("separation", 12)
	left_padding.add_child(left_layout)

	var header := HBoxContainer.new()
	left_layout.add_child(header)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)

	title_label = make_label("", 20, INK)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(title_label)

	subtitle_label = make_label("", 13, MUTED_INK)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(subtitle_label)

	left_layout.add_child(HSeparator.new())

	left_entries = VBoxContainer.new()
	left_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	right_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_page.clip_contents = true
	right_page.add_theme_stylebox_override("panel", make_page_style(false))
	open_pages.add_child(right_page)

	var right_padding := MarginContainer.new()
	add_page_margins(right_padding)
	right_page.add_child(right_padding)

	var right_layout := VBoxContainer.new()
	right_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_layout.add_theme_constant_override("separation", 12)
	right_padding.add_child(right_layout)

	var daily_log := make_label("DAILY LOG", 13, MUTED_INK)
	right_layout.add_child(daily_log)

	right_layout.add_child(HSeparator.new())

	right_entries = VBoxContainer.new()
	right_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

	left_tabs = Control.new()
	left_tabs.custom_minimum_size.x = 94
	left_tabs.anchor_left = 0.0
	left_tabs.anchor_right = 0.0
	left_tabs.anchor_top = 0.18
	left_tabs.anchor_bottom = 0.18
	left_tabs.offset_left = -18
	left_tabs.offset_right = 76
	left_tabs.offset_top = 0
	left_tabs.offset_bottom = 290
	tab_layer.add_child(left_tabs)

	right_tabs = Control.new()
	right_tabs.custom_minimum_size.x = 94
	right_tabs.anchor_left = 1.0
	right_tabs.anchor_right = 1.0
	right_tabs.anchor_top = 0.18
	right_tabs.anchor_bottom = 0.18
	right_tabs.offset_left = -76
	right_tabs.offset_right = 18
	right_tabs.offset_top = 0
	right_tabs.offset_bottom = 290
	tab_layer.add_child(right_tabs)


func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:

		close_logbook()
		get_viewport().set_input_as_handled()


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
	first_half.set_trans(Tween.TRANS_SINE)
	first_half.set_ease(Tween.EASE_IN_OUT)
	first_half.tween_property(page_curl, "progress", 0.5, 0.62)

	await first_half.finished

	show_page(index)

	var second_half := create_tween()
	second_half.set_trans(Tween.TRANS_SINE)
	second_half.set_ease(Tween.EASE_IN_OUT)
	second_half.tween_property(page_curl, "progress", 1.0, 0.62)

	await second_half.finished

	page_curl.visible = false
	turning = false


func show_page(index: int) -> void:
	if pages.is_empty():
		return

	current_page = clampi(index, 0, pages.size() - 1)

	var page: Dictionary = pages[current_page]

	title_label.text = str(page.get("title", ""))
	subtitle_label.text = str(page.get("subtitle", ""))

	title_label.visible = page.has("title")
	subtitle_label.visible = page.has("subtitle")

	for container in [left_entries, right_entries]:
		for child in container.get_children():
			child.queue_free()

	if page.has("columns") and page.has("rows"):
		add_table(page)

	if page.has("notes"):
		add_notes(page)

	if page.has("details"):
		add_details(page)

	if page.has("key_points"):
		add_key_points(page)

	page_number.text = "—  %d / %d  —" % [
		current_page + 1,
		pages.size()
	]

	rebuild_tabs()


func add_table(page: Dictionary) -> void:
	var columns: Array = page["columns"]
	var rows: Array = page["rows"]

	if columns.size() >= 2:
		var header := HBoxContainer.new()
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_theme_constant_override("separation", 12)

		var first_header := make_label(str(columns[0]), 11, MUTED_INK)
		first_header.custom_minimum_size.x = 80
		header.add_child(first_header)

		var second_header := make_label(str(columns[1]), 11, MUTED_INK)
		second_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(second_header)

		left_entries.add_child(header)
		left_entries.add_child(HSeparator.new())

	for row_data in rows:
		if row_data.size() < 2:
			continue

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)

		var first_value := make_label(str(row_data[0]), 11, INK)
		first_value.custom_minimum_size.x = 80
		first_value.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		first_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(first_value)

		var second_value := make_label(str(row_data[1]), 11, INK)
		second_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		second_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		second_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(second_value)

		left_entries.add_child(row)

func add_details(page: Dictionary) -> void:
	left_entries.add_child(make_section_heading("SECTION DETAILS"))

	var label := make_label(str(page["details"]), 11, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	left_entries.add_child(label)
func add_notes(page: Dictionary) -> void:
	right_entries.add_child(make_section_heading("NOTES"))

	var label := make_label(str(page["notes"]), 11, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	right_entries.add_child(label)





func add_key_points(page: Dictionary) -> void:
	right_entries.add_child(make_section_heading("KEY POINTS"))

	for point in page["key_points"]:
		var label := make_label("•  " + str(point), 11, INK)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_entries.add_child(label)


func rebuild_tabs() -> void:
	for container in [left_tabs, right_tabs]:
		for child in container.get_children():
			child.queue_free()

	for index in pages.size():
		if index == current_page:
			continue

		var tab := StickyTabScript.new() as Button

		tab.text = "%d\n%s" % [
			index + 1,
			str(pages[index].get("tab", "")).replace(" ", "\n")
		]

		tab.custom_minimum_size = Vector2(94, 64)
		tab.pressed.connect(turn_to_page.bind(index))

		var destination := left_tabs if index < current_page else right_tabs

		tab.call(
			"configure",
			TAB_COLORS[index % TAB_COLORS.size()],
			destination == right_tabs
		)

		destination.add_child(tab)

		tab.position = Vector2(0, index * 70)

		tab.rotation = deg_to_rad(
			-0.45 if destination == left_tabs else 0.45
		)

		tab.pivot_offset = tab.custom_minimum_size * 0.5


func make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()

	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

	return label


func add_page_margins(container: MarginContainer) -> void:
	container.add_theme_constant_override("margin_left", 40)
	container.add_theme_constant_override("margin_right", 40)
	container.add_theme_constant_override("margin_top", 24)
	container.add_theme_constant_override("margin_bottom", 24)


func make_section_heading(text_value: String) -> VBoxContainer:
	var section := VBoxContainer.new()

	section.add_theme_constant_override("separation", 4)
	section.add_child(make_label(text_value, 12, INK))
	section.add_child(HSeparator.new())

	return section


func make_style(
	fill: Color,
	border: Color,
	border_width: int,
	radius: int,
	margin: int
) -> StyleBoxFlat:

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
	var style := make_style(
		Color.TRANSPARENT,
		Color.TRANSPARENT,
		0,
		0,
		0
	)

	style.corner_radius_top_right = 1 if is_left else 5
	style.corner_radius_bottom_right = 1 if is_left else 5
	style.corner_radius_top_left = 5 if is_left else 1
	style.corner_radius_bottom_left = 5 if is_left else 1

	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0

	return style


func make_turning_style() -> StyleBoxFlat:
	var style := make_style(
		Color("e1d1ad"),
		PAPER_DARK,
		1,
		4,
		18
	)

	style.shadow_color = Color(0.04, 0.025, 0.015, 0.72)
	style.shadow_size = 18
	style.shadow_offset = Vector2(-12, 5)

	return style

#class_name LogbookUI
#extends Control
#
#const PageCurlScript = preload("res://Scripts/Logbook/PageCurl2D.gd")
#const StickyTabScript = preload("res://Scripts/Logbook/StickyBookmarkButton.gd")
#const BINDER_TEXTURE = preload("res://Assets/UI/Logbook/logbook_open_binder.png")
#
#const INK := Color("332b23")
#const MUTED_INK := Color("6f6354")
#const PAPER := Color("d8c7a2")
#const PAPER_DARK := Color("bea980")
#const COVER := Color("3b2b22")
#const TAB_COLORS := [Color("d2a23f"), Color("9eb7bf"), Color("cf8078"), Color("a5a95d"), Color("c97b3d")]
#
##var pages: Array[Dictionary] = [
	###{"tab":"SHIFT", "title":"SHIFT 1  •  AUGUST 26", "subtitle":"6:00 PM — 6:00 AM", "columns":["TIME","LOG ENTRY"], "rows":[["6:00 PM","Shift opened; roster synchronized at 5:45 PM."],["7:40 PM","Tracey Miller authorized visitor Maya Chen."],["9:00 PM","Room 102 checkout deadline."],["12:00 AM","Roster update window begins."]], "details":"Night reception duty. Review every visitor against the roster and the resident's call.", "key_points":["Confirm the host and room number.","Check the stated arrival window.","Record every access decision."], "notes":"Roster information may conflict during the midnight update."},
	##{"tab":"VISITORS", "title":"EXPECTED VISITORS", "subtitle":"Verify identity and arrival window", "columns":["TIME","VISITOR / HOST"], "rows":[["8:30–9:15","Maya Chen — Tracey Miller, Room 101."],["10:15–11:00","Clara Hayes — William Hayes, Room 103."],["11:30–12:00","Daniel Ortiz — Nina Patel, Room 104."]], "details":"Only visitors recorded by a resident may enter. A matching name by itself is not proof.", "key_points":["Request the visitor's ID.","Confirm the resident's full name.","Verify one fixed detail."], "notes":"Keep the original resident call time beside each authorization."},
	##{"tab":"RESIDENTS", "title":"RESIDENT NOTES", "subtitle":"Requirements and exceptions", "columns":["",""], "rows":[["101","Tracey Miller — phone ending 7734."],["103","William Hayes — impaired hearing."],["104","Nina Patel — visitor expected before midnight."],["107","Marcus Reed — returning after midnight."]], "details":"Resident notes contain accessibility requirements and exceptions that affect verification.", "key_points":["Allow extra time when required.","Never reveal private roster details.","Cross-check visitor authorization."], "notes":"Repeat questions clearly for William Hayes in Room 103."},
	###{"tab":"INCIDENTS", "title":"INCIDENT REPORTS", "subtitle":"Security and maintenance record", "columns":["TIME","INCIDENT"], "rows":[["6:25 PM","Lobby camera signal lost; restored 6:31 PM."],["7:05 PM","Room 102 checkout recorded."],["8:05 PM","Unknown visitor claimed Room 102 access."]], "details":"Unusual activity, access attempts, and equipment failures must be recorded here.", "key_points":["Note the exact time.","Record the claimed identity.","Escalate repeated attempts."], "notes":"No maintenance staff are scheduled after 10:00 PM."},
##]
#

#var current_page := 0
#var turning := false
#var left_tabs: Control
#var right_tabs: Control
#var page_surface: PanelContainer
#var title_label: Label
#var subtitle_label: Label
#var left_entries: VBoxContainer
#var right_entries: VBoxContainer
#var page_number: Label
#var left_page: PanelContainer
#var right_page: PanelContainer
#var turning_page: PanelContainer
#var page_curl: Control
#var book_spine: ColorRect
#var curl_layer: Control
#var tab_layer: Control
#
#func _ready() -> void:
	#add_to_group("logbook_ui")
	#add_to_group("desk_ui")
	#build_interface()
	#show_page(0)
	#visible = false
#
#func _input(event: InputEvent) -> void:
	#if not visible:
		#return
	#if event.is_action_pressed("ui_cancel"):
		#close_logbook()
		#get_viewport().set_input_as_handled()
	#elif event is InputEventMouseButton \
		#and event.button_index == MOUSE_BUTTON_LEFT \
		#and event.pressed \
		#and not is_point_over_book(event.position):
		#close_logbook()
		#get_viewport().set_input_as_handled()
#
#func is_point_over_book(screen_position: Vector2) -> bool:
	#if page_surface == null:
		#return false
	## Include the small bookmark overhangs as part of the book interaction area.
	#return page_surface.get_global_rect().grow(20.0).has_point(screen_position)
#
#func open_logbook() -> void:
	#visible = true
	#move_to_front()
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
#
#func close_logbook() -> void:
	#visible = false
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#
#func build_interface() -> void:
	#set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#mouse_filter = Control.MOUSE_FILTER_STOP
	#var dimmer := ColorRect.new()
	#dimmer.color = Color(0.025, 0.02, 0.016, 0.80)
	#dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	#dimmer.gui_input.connect(_on_background_input)
	#add_child(dimmer)
	#var layout := AspectRatioContainer.new()
	#layout.ratio = 1.5
	#layout.stretch_mode = AspectRatioContainer.STRETCH_FIT
	#layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 34)
	#add_child(layout)
	#left_tabs = Control.new()
	#left_tabs.custom_minimum_size.x = 94
	#page_surface = PanelContainer.new()
	#page_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#page_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#page_surface.add_theme_stylebox_override("panel", make_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0))
	#layout.add_child(page_surface)
	#var binder_art := TextureRect.new()
	#binder_art.name = "LeatherBinderArtwork"
	#binder_art.texture = BINDER_TEXTURE
	#binder_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	#binder_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#binder_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#page_surface.add_child(binder_art)
	#var book_margin := MarginContainer.new()
	#book_margin.add_theme_constant_override("margin_left", 70)
	#book_margin.add_theme_constant_override("margin_right", 70)
	#book_margin.add_theme_constant_override("margin_top", 54)
	#book_margin.add_theme_constant_override("margin_bottom", 54)
	#page_surface.add_child(book_margin)
	#var open_pages := HBoxContainer.new()
	#open_pages.add_theme_constant_override("separation", 8)
	#book_margin.add_child(open_pages)
	#left_page = PanelContainer.new()
	#left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#left_page.clip_contents = true
	#left_page.add_theme_stylebox_override("panel", make_page_style(true))
	#open_pages.add_child(left_page)
	#var left_padding := MarginContainer.new()
	#add_page_margins(left_padding)
	#left_page.add_child(left_padding)
	#var left_layout := VBoxContainer.new()
	#left_layout.add_theme_constant_override("separation", 12)
	#left_padding.add_child(left_layout)
	#var header := HBoxContainer.new()
	#left_layout.add_child(header)
	#var heading := VBoxContainer.new()
	#heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#header.add_child(heading)
	#title_label = make_label("", 20, INK)
	#title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	#heading.add_child(title_label)
	#subtitle_label = make_label("", 13, MUTED_INK)
	#heading.add_child(subtitle_label)
	#left_layout.add_child(HSeparator.new())
	#left_entries = VBoxContainer.new()
	#left_entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#left_entries.add_theme_constant_override("separation", 10)
	#left_layout.add_child(left_entries)
	#book_spine = ColorRect.new()
	#book_spine.color = Color(0.12, 0.075, 0.04, 0.50)
	#book_spine.custom_minimum_size.x = 14
	#book_spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#open_pages.add_child(book_spine)
	#right_page = PanelContainer.new()
	#right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#right_page.clip_contents = true
	#right_page.add_theme_stylebox_override("panel", make_page_style(false))
	#open_pages.add_child(right_page)
	#var right_padding := MarginContainer.new()
	#add_page_margins(right_padding)
	#right_page.add_child(right_padding)
	#var right_layout := VBoxContainer.new()
	#right_layout.add_theme_constant_override("separation", 12)
	#right_padding.add_child(right_layout)
	#var daily_log := make_label("DAILY LOG  •  CONTINUED", 13, MUTED_INK)
	#daily_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#right_layout.add_child(daily_log)
	#right_layout.add_child(HSeparator.new())
	#right_entries = VBoxContainer.new()
	#right_entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#right_entries.add_theme_constant_override("separation", 10)
	#right_layout.add_child(right_entries)
	#page_number = make_label("", 14, MUTED_INK)
	#page_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#right_layout.add_child(page_number)
	#turning_page = PanelContainer.new()
	#turning_page.visible = false
	#turning_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#turning_page.add_theme_stylebox_override("panel", make_turning_style())
	#page_surface.add_child(turning_page)
	#curl_layer = Control.new()
	#curl_layer.name = "PageTurnOverlayLayer"
	#curl_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#curl_layer.clip_contents = false
	#page_surface.add_child(curl_layer)
	#page_curl = PageCurlScript.new()
	#page_curl.name = "PageCurl2D"
	#page_curl.visible = false
	#curl_layer.add_child(page_curl)
	#tab_layer = Control.new()
	#tab_layer.name = "StickyBookmarkLayer"
	#tab_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#tab_layer.clip_contents = false
	#page_surface.add_child(tab_layer)
	#left_tabs.anchor_left = 0.0
	#left_tabs.anchor_right = 0.0
	#left_tabs.anchor_top = 0.18
	#left_tabs.anchor_bottom = 0.18
	#left_tabs.offset_left = -18
	#left_tabs.offset_right = 76
	#left_tabs.offset_top = 0
	#left_tabs.offset_bottom = 290
	#tab_layer.add_child(left_tabs)
	#right_tabs = Control.new()
	#right_tabs.custom_minimum_size.x = 94
	#right_tabs.anchor_left = 1.0
	#right_tabs.anchor_right = 1.0
	#right_tabs.anchor_top = 0.18
	#right_tabs.anchor_bottom = 0.18
	#right_tabs.offset_left = -76
	#right_tabs.offset_right = 18
	#right_tabs.offset_top = 0
	#right_tabs.offset_bottom = 290
	#tab_layer.add_child(right_tabs)
#
#func _on_background_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton \
		#and event.button_index == MOUSE_BUTTON_LEFT \
		#and event.pressed:
		#close_logbook()
		#get_viewport().set_input_as_handled()
#
#func turn_to_page(index: int) -> void:
	#if turning or index == current_page:
		#return
	#turning = true
	#var forward := index > current_page
	#var source_page: Control = right_page if forward else left_page
	#var spine_x := book_spine.global_position.x + book_spine.size.x * 0.5
	#page_curl.position = Vector2(
		#spine_x - curl_layer.global_position.x,
		#source_page.global_position.y - curl_layer.global_position.y
	#)
	#page_curl.size = source_page.size
	#page_curl.begin(forward)
	#var first_half := create_tween()
	#first_half.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#first_half.tween_property(page_curl, "progress", 0.5, 0.62)
	#await first_half.finished
	#show_page(index)
	#var second_half := create_tween()
	#second_half.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#second_half.tween_property(page_curl, "progress", 1.0, 0.62)
	#await second_half.finished
	#page_curl.visible = false
	#turning = false
#
#func configure_turning_page(target_page: Control, starts_open: bool) -> void:
	#turning_page.position = target_page.global_position - page_surface.global_position
	#turning_page.size = target_page.size
	#turning_page.pivot_offset = Vector2(0, target_page.size.y * 0.5) if starts_open else Vector2(target_page.size.x, target_page.size.y * 0.5)
	#turning_page.scale = Vector2(1.0 if starts_open else 0.035, 1.0)
	#turning_page.rotation = 0.0 if starts_open else 0.035
#
#func finish_page_turn() -> void:
	#turning_page.visible = false
	#turning = false
#
#func show_page(index: int) -> void:
	#current_page = clampi(index, 0, pages.size() - 1)
	#var page := pages[current_page]
	#title_label.text = str(page.title)
	#subtitle_label.text = str(page.subtitle)
	#for container in [left_entries, right_entries]:
		#for child in container.get_children():
			#container.remove_child(child)
			#child.queue_free()
	#var table_header := HBoxContainer.new()
	#table_header.add_theme_constant_override("separation", 12)
	#var first_column_header := make_label(str(page.columns[0]), 11, MUTED_INK)
	#first_column_header.custom_minimum_size.x = 62
	#first_column_header.clip_text = true
	#table_header.add_child(first_column_header)
	#var second_column_header := make_label(str(page.columns[1]), 11, MUTED_INK)
	#second_column_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#second_column_header.clip_text = true
	#table_header.add_child(second_column_header)
	#left_entries.add_child(table_header)
	#left_entries.add_child(HSeparator.new())
	#for row_data in page.rows:
		#var row := HBoxContainer.new()
		#row.custom_minimum_size.y = 38
		#row.add_theme_constant_override("separation", 12)
		#var first_value := make_label(str(row_data[0]), 11, INK)
		#first_value.custom_minimum_size.x = 62
		#first_value.clip_text = true
		#first_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		#row.add_child(first_value)
		#var second_value := make_label(str(row_data[1]), 11, INK)
		#second_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		#second_value.clip_text = true
		#second_value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		#second_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		#second_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#row.add_child(second_value)
		#left_entries.add_child(row)
	#var notes_heading := make_section_heading("NOTES")
	#left_entries.add_child(notes_heading)
	#var notes_label := make_label(str(page.notes), 11, INK)
	#notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#notes_label.clip_text = true
	#left_entries.add_child(notes_label)
#
	#right_entries.add_child(make_section_heading("SECTION DETAILS"))
	#var detail_label := make_label(str(page.details), 11, INK)
	#detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#detail_label.clip_text = true
	#detail_label.custom_minimum_size.y = 76
	#right_entries.add_child(detail_label)
	#right_entries.add_child(make_section_heading("KEY POINTS"))
	#for point in page.key_points:
		#var point_label := make_label("•  " + str(point), 11, INK)
		#point_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		#point_label.clip_text = true
		#point_label.custom_minimum_size.y = 26
		#right_entries.add_child(point_label)
	#page_number.text = "—  %d / %d  —" % [current_page + 1, pages.size()]
	#rebuild_tabs()
#
#func rebuild_tabs() -> void:
	#for container in [left_tabs, right_tabs]:
		#for child in container.get_children(): child.queue_free()
	#for index in pages.size():
		#if index == current_page:
			#continue
		#var tab := StickyTabScript.new() as Button
		#tab.text = "%d\n%s" % [index + 1, str(pages[index].tab).replace(" ", "\n")]
		#tab.custom_minimum_size = Vector2(94, 64)
		#tab.pressed.connect(turn_to_page.bind(index))
		#var destination := left_tabs if index < current_page else right_tabs
		## Right bookmarks expose their right edge; left bookmarks expose left.
		#tab.call("configure", TAB_COLORS[index], destination == right_tabs)
		#destination.add_child(tab)
		#tab.position = Vector2(0, index * 70)
		#tab.rotation = deg_to_rad(-0.45 if destination == left_tabs else 0.45)
		#tab.pivot_offset = tab.custom_minimum_size * 0.5
#
#func make_label(text_value: String, font_size: int, color: Color) -> Label:
	#var label := Label.new()
	#label.text = text_value
	#label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	#label.add_theme_font_size_override("font_size", font_size)
	#label.add_theme_color_override("font_color", color)
	#return label
#
#func add_page_margins(container: MarginContainer) -> void:
	## The binder texture includes stacked page edges outside the usable sheet.
	## Keep content inside the visible paper rather than the larger control bounds.
	#container.add_theme_constant_override("margin_left", 40)
	#container.add_theme_constant_override("margin_right", 40)
	#container.add_theme_constant_override("margin_top", 24)
	#container.add_theme_constant_override("margin_bottom", 24)
#
#func make_section_heading(text_value: String) -> VBoxContainer:
	#var section := VBoxContainer.new()
	#section.add_theme_constant_override("separation", 4)
	#section.add_child(make_label(text_value, 12, INK))
	#section.add_child(HSeparator.new())
	#return section
#
#func make_style(fill: Color, border: Color, border_width: int, radius: int, margin: int) -> StyleBoxFlat:
	#var style := StyleBoxFlat.new()
	#style.bg_color = fill
	#style.border_color = border
	#style.set_border_width_all(border_width)
	#style.set_corner_radius_all(radius)
	#style.content_margin_left = margin
	#style.content_margin_right = margin
	#style.content_margin_top = margin
	#style.content_margin_bottom = margin
	#return style
#
#func make_page_style(is_left: bool) -> StyleBoxFlat:
	#var style := make_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0)
	#style.corner_radius_top_right = 1 if is_left else 5
	#style.corner_radius_bottom_right = 1 if is_left else 5
	#style.corner_radius_top_left = 5 if is_left else 1
	#style.corner_radius_bottom_left = 5 if is_left else 1
	#style.shadow_color = Color.TRANSPARENT
	#style.shadow_size = 0
	#return style
#
#func make_turning_style() -> StyleBoxFlat:
	#var style := make_style(Color("e1d1ad"), PAPER_DARK, 1, 4, 18)
	#style.shadow_color = Color(0.04, 0.025, 0.015, 0.72)
	#style.shadow_size = 18
	#style.shadow_offset = Vector2(-12, 5)
	#return style
