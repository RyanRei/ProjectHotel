class_name PageCurl2D
extends Control

@export_range(0.0, 1.0) var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var forward := true
const PAPER := Color("e1d1ad")
const PAPER_BACK := Color("d3bd91")
const STRIPS := 32

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

func begin(is_forward: bool) -> void:
	forward = is_forward
	progress = 0.0
	visible = true

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var angle := progress * PI
	var starting_side := 1.0 if forward else -1.0
	var top_points := PackedVector2Array()
	var bottom_points := PackedVector2Array()
	for strip_index in range(STRIPS + 1):
		var u := float(strip_index) / float(STRIPS)
		# u=0 is always the centre spine. Extra rotation toward the outside
		# edge makes the sheet bow instead of behaving like a flat door.
		var local_angle := angle + sin(u * PI) * sin(angle) * 0.42
		var x := starting_side * cos(local_angle) * u * size.x
		var bow := sin(local_angle) * sin(u * PI) * 15.0
		top_points.append(Vector2(x, bow))
		bottom_points.append(Vector2(x, size.y - bow))
	var page_polygon := PackedVector2Array()
	for point in top_points:
		page_polygon.append(point)
	for point_index in range(bottom_points.size() - 1, -1, -1):
		page_polygon.append(bottom_points[point_index])
	var shadow_offset := Vector2(starting_side * cos(angle) * 10.0, 8.0)
	var shadow_polygon := PackedVector2Array()
	for point in page_polygon:
		shadow_polygon.append(point + shadow_offset)
	draw_colored_polygon(shadow_polygon, Color(0.04, 0.025, 0.015, 0.42))
	for strip_index in range(STRIPS):
		var strip_phase := float(strip_index) / float(STRIPS)
		var shade := 0.76 + absf(cos(angle + strip_phase * 0.35)) * 0.24
		var base := PAPER if progress < 0.5 else PAPER_BACK
		var strip_color := Color(base.r * shade, base.g * shade, base.b * shade, 1.0)
		var quad := PackedVector2Array([
			top_points[strip_index], top_points[strip_index + 1],
			bottom_points[strip_index + 1], bottom_points[strip_index]
		])
		draw_colored_polygon(quad, strip_color)
	draw_polyline(top_points, Color(0.30, 0.23, 0.16, 0.55), 1.25, true)
	draw_polyline(bottom_points, Color(0.30, 0.23, 0.16, 0.55), 1.25, true)
	draw_line(Vector2.ZERO, Vector2(0.0, size.y), Color(0.20, 0.14, 0.10, 0.92), 3.0, true)
