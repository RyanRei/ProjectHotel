@tool
class_name NewspaperReport2D
extends Node2D

@export var auto_fit_viewport := true
@export var play_animation_on_start := true
@export var design_size := Vector2(1536.0, 1024.0)
@export_range(0.25, 1.2, 0.05) var throw_duration := 0.42

@onready var display: Node2D = %Display
@onready var paper: Node2D = %Paper
@onready var instruction: Label = %Instruction

var _animation: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if auto_fit_viewport:
		get_viewport().size_changed.connect(_fit_to_viewport)
		_fit_to_viewport()
	if play_animation_on_start:
		play_report_animation()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event.is_action_pressed("ui_accept"):
		play_report_animation()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		play_report_animation()


func play_report_animation() -> void:
	if _animation and _animation.is_valid():
		_animation.kill()

	# Throw the report toward the viewer, impact the screen, then settle exactly.
	var distant_scale := 0.035
	var screen_center := design_size * 0.5
	paper.modulate = Color(0.62, 0.59, 0.54, 0.72)
	paper.scale = Vector2.ONE * distant_scale
	# Offset compensates for Node2D scaling so the newspaper starts at screen center.
	paper.position = screen_center * (1.0 - distant_scale)
	paper.rotation = deg_to_rad(-4.5)
	instruction.modulate.a = 0.0
	var stick_details: Array[Node] = []
	for node in get_tree().get_nodes_in_group(&"stick_detail"):
		if is_ancestor_of(node):
			stick_details.append(node)
			node.modulate.a = 0.0

	_animation = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.tween_property(paper, "position", Vector2(-20.0, 14.0), throw_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_animation.parallel().tween_property(paper, "scale", Vector2(1.085, 1.085), throw_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_animation.parallel().tween_property(paper, "rotation", deg_to_rad(2.2), throw_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_animation.parallel().tween_property(paper, "modulate", Color.WHITE, throw_duration)
	_animation.tween_callback(_paper_impact)
	_animation.tween_property(paper, "position", Vector2(11.0, -7.0), 0.065).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_animation.parallel().tween_property(paper, "rotation", deg_to_rad(-1.0), 0.065)
	_animation.parallel().tween_property(paper, "scale", Vector2(0.982, 0.982), 0.065)
	_animation.tween_property(paper, "position", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_animation.parallel().tween_property(paper, "rotation", 0.0, 0.14)
	_animation.parallel().tween_property(paper, "scale", Vector2.ONE, 0.14)
	for detail in stick_details:
		_animation.parallel().tween_property(detail, "modulate:a", 1.0, 0.16)
	_animation.tween_callback(_finish_impact)
	_animation.tween_property(instruction, "modulate:a", 0.8, 0.25)


func _paper_impact() -> void:
	pass


func _finish_impact() -> void:
	# Eliminate interpolation differences so the final UI matches the editor.
	paper.scale = Vector2.ONE
	paper.position = Vector2.ZERO
	paper.rotation = 0.0
	paper.modulate = Color.WHITE


func set_report(report: Dictionary) -> void:
	# Optional runtime hook; designers can also edit every Label directly in the scene.
	if report.has("headline"):
		%Headline.text = str(report.headline)
	if report.has("subheadline"):
		%Subheadline.text = str(report.subheadline)
	if report.has("reputation"):
		%ReputationValue.text = "%s / 100" % str(report.reputation)
	if report.has("share_price"):
		%ShareValue.text = "$%.2f" % float(report.share_price)
	if report.has("reputation_change"):
		_set_metric_change(%ReputationDelta, float(report.reputation_change), "")
	if report.has("share_change_percent"):
		_set_metric_change(%ShareDelta, float(report.share_change_percent), "%")
	# Swap this with another pre-generated full-scene illustration for later shifts.
	if report.has("outcome_image") and report.outcome_image is Texture2D:
		%OutcomeImage.texture = report.outcome_image


func set_metric_changes(reputation_change: float, share_change_percent: float) -> void:
	_set_metric_change(%ReputationDelta, reputation_change, "")
	_set_metric_change(%ShareDelta, share_change_percent, "%")


func _set_metric_change(label: Label, change: float, suffix: String) -> void:
	var sign_text := "+" if change > 0.0 else ""
	label.text = "(%s%s%s)" % [sign_text, _compact_number(change), suffix]
	if change < 0.0:
		label.add_theme_color_override("font_color", Color("a52f28"))
	elif change > 0.0:
		label.add_theme_color_override("font_color", Color("2f713d"))
	else:
		label.add_theme_color_override("font_color", Color("5b5145"))


func _compact_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return "%.1f" % value


func _fit_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var fit_scale: float = minf(viewport_size.x / design_size.x, viewport_size.y / design_size.y) * 0.96
	display.scale = Vector2.ONE * fit_scale
	display.position = (viewport_size - design_size * fit_scale) * 0.5
