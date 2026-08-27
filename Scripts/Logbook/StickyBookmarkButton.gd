class_name StickyBookmarkButton
extends Button

var paper_color := Color("b98a36")
var points_right := true

func _ready() -> void:
	flat = true
	clip_text = false
	add_theme_font_size_override("font_size", 11)
	add_theme_color_override("font_color", Color("2d261e"))
	add_theme_color_override("font_hover_color", Color("1d1813"))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func configure(color_value: Color, faces_right: bool) -> void:
	paper_color = color_value
	points_right = faces_right
	queue_redraw()

func _draw() -> void:
	var width := size.x
	var height := size.y
	var cut := 8.0
	var shape := PackedVector2Array()
	if points_right:
		shape = PackedVector2Array([Vector2(0, 0), Vector2(width - cut, 0), Vector2(width, cut), Vector2(width, height - cut), Vector2(width - cut, height), Vector2(0, height)])
	else:
		shape = PackedVector2Array([Vector2(cut, 0), Vector2(width, 0), Vector2(width, height), Vector2(cut, height), Vector2(0, height - cut), Vector2(0, cut)])
	var shadow := PackedVector2Array()
	for point in shape:
		shadow.append(point + Vector2(3, 4))
	draw_colored_polygon(shadow, Color(0.035, 0.02, 0.01, 0.62))
	var fill := paper_color.lightened(0.13) if is_hovered() else paper_color
	if is_pressed():
		fill = fill.darkened(0.08)
	draw_colored_polygon(shape, fill)
	# A darker strip is the section tucked beneath the page stack.
	var buried_strip := PackedVector2Array()
	if points_right:
		buried_strip = PackedVector2Array([Vector2(0, 1), Vector2(9, 1), Vector2(9, height - 1), Vector2(0, height - 1)])
	else:
		buried_strip = PackedVector2Array([Vector2(width - 9, 1), Vector2(width, 1), Vector2(width, height - 1), Vector2(width - 9, height - 1)])
	draw_colored_polygon(buried_strip, Color(0.20, 0.14, 0.08, 0.16))
	# Subtle fibres keep the control from looking like a flat UI rectangle.
	for grain_y in [13.0, 31.0, 49.0]:
		draw_line(Vector2(12, grain_y), Vector2(width - 12, grain_y + 0.5), Color(1, 0.93, 0.76, 0.10), 1.0)
	draw_polyline(shape + PackedVector2Array([shape[0]]), Color("493629"), 1.5, true)
	var crease_x := 10.0 if points_right else width - 10.0
	draw_line(Vector2(crease_x, 7), Vector2(crease_x, height - 7), Color(0.25, 0.18, 0.12, 0.30), 1.0)
	# Overriding Button._draw also replaces its native label rendering, so the
	# bookmark draws its own centered section number and name.
	var font := ThemeDB.fallback_font
	var lines := text.split("\n", false)
	var font_size := 10
	var line_height := 13.0
	var block_height := float(lines.size()) * line_height
	var first_baseline := (height - block_height) * 0.5 + float(font_size)
	for line_index in lines.size():
		var line := str(lines[line_index])
		var line_width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(
			font,
			Vector2((width - line_width) * 0.5, first_baseline + line_index * line_height),
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color("2d261e")
		)
