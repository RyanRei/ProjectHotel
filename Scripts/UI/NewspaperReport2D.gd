@tool
class_name NewspaperReport2D
extends Node2D

signal report_closed

const NEUTRAL_SHIFT_IMAGE: Texture2D = preload("res://Assets/UI/Newspaper/neutral_safe_shift.png")
const CRIME_OUTSIDE_IMAGE: Texture2D = preload("res://Assets/UI/Newspaper/crime_outside.jpg")
const CRIME_INSIDE_IMAGE: Texture2D = preload("res://Assets/UI/Newspaper/crime_inside.png")

@export var auto_fit_viewport := true
@export var play_animation_on_start := true
@export var standalone_mode := true
@export var design_size := Vector2(1536.0, 1024.0)
@export_range(0.25, 1.2, 0.05) var throw_duration := 0.42

@onready var display: Node2D = %Display
@onready var paper: Node2D = %Paper
@onready var instruction: Label = %Instruction

var _animation: Tween
var _can_close := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if auto_fit_viewport:
		get_viewport().size_changed.connect(_fit_to_viewport)
		_fit_to_viewport()
	instruction.text = "CLICK / ENTER: REPLAY     ESC: CLOSE" if standalone_mode else "CLICK / ENTER: CONTINUE"
	if play_animation_on_start:
		play_report_animation()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not visible:
		return
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if standalone_mode:
		if event.is_action_pressed("ui_cancel"):
			get_tree().quit()
		elif event.is_action_pressed("ui_accept") or clicked:
			play_report_animation()
	elif _can_close and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or clicked):
		_can_close = false
		# Closing the final report can synchronously change to the main-menu
		# scene and free this node. Consume the input while the viewport is still
		# valid, before notifying the end-of-day flow.
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		report_closed.emit()


func show_report(report: Dictionary) -> void:
	visible = true
	_can_close = false
	set_report(report)
	play_report_animation()
	if _animation and _animation.is_valid():
		await _animation.finished
	_can_close = true
	await report_closed
	visible = false


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
	if report.has("day"):
		$Display/Paper/Edition.text = "MORNING REPORT\nSHIFT %d" % int(report.day)
	if report.has("results"):
		_apply_results(report.results, report.get("story_flags", {}), int(report.get("day", 1)))


func _apply_results(results: Array, story_flags: Dictionary = {}, report_day: int = 1) -> void:
	var successes := 0
	var weighted_successes := 0.0
	var weighted_failures := 0.0
	var has_outside_crime := false
	var has_inside_crime := false
	for index in range(4):
		var card := paper.get_node_or_null("Outcome%d" % (index + 1))
		if card == null:
			continue
		card.visible = index < results.size()
		if index >= results.size():
			continue
		var result: Dictionary = results[index]
		var succeeded := str(result.get("status", "FAIL")) == "SUCCESS"
		var consequence := str(result.get("consequence", "NONE"))
		has_inside_crime = has_inside_crime or consequence == "INSIDE"
		has_outside_crime = has_outside_crime or consequence == "OUTSIDE"
		if succeeded:
			successes += 1
			weighted_successes += float(result.get("weight", 1.0))
		else:
			weighted_failures += float(result.get("weight", 1.0))
		card.get_node("Name").text = str(result.get("name", "UNKNOWN")).to_upper()
		card.get_node("Result").text = "CORRECT DECISION" if succeeded else "WRONG DECISION"
		card.get_node("StatusBand").color = Color("71824b") if succeeded else Color("94382c")
		card.get_node("Details").text = _get_result_details(str(result.get("id", "")), succeeded, story_flags)

	var total := results.size()
	var failures := total - successes
	%BreakdownTitle.text = "DECISION BREAKDOWN - %d OF %d CORRECT" % [successes, total]
	var ven_inside_death := bool(story_flags.get("ven_inside_death", false))
	var ven_outside_death := bool(story_flags.get("ven_outside_death", false))
	if has_inside_crime or ven_inside_death:
		%OutcomeImage.texture = CRIME_INSIDE_IMAGE
		%PhotoCaption.text = "CRIME SCENE PHOTOGRAPH — INCIDENT INSIDE NIGHTHAVEN"
	elif has_outside_crime:
		%OutcomeImage.texture = CRIME_OUTSIDE_IMAGE
		%PhotoCaption.text = "CRIME SCENE PHOTOGRAPH — STREET OUTSIDE NIGHTHAVEN"
	else:
		%OutcomeImage.texture = NEUTRAL_SHIFT_IMAGE
		%PhotoCaption.text = "MORNING PHOTOGRAPH — NIGHTHAVEN REMAINED SECURE"
	if ven_inside_death:
		%Headline.text = "POP STAR VEN KEER KILLED INSIDE NIGHTHAVEN"
		%Subheadline.text = "Public outrage follows a fatal security breach inside Room 412"
	elif ven_outside_death:
		%Headline.text = "VEN KEER TURNED AWAY, KILLED OUTSIDE SHELTER"
		%Subheadline.text = "Night operator rejected the star minutes before the fatal street attack"
	else:
		%Headline.text = "QUIET NIGHT FOR SECRET VIP GUEST" if failures == 0 else "NIGHTHAVEN STOPS LATE-NIGHT SECURITY THREATS"
		%Subheadline.text = "%d of %d decisions were correct; Ven Keer remained safe" % [successes, total]
	var starting_reputation: float = float(GameState.reputation)
	var starting_share_price: float = float(GameState.share_price)
	var vip_penalty := 12.0 if ven_inside_death or ven_outside_death else 0.0
	var reputation_change := weighted_successes * 2.0 - weighted_failures * 4.0 - vip_penalty
	var share_change := weighted_successes * 1.25 - weighted_failures * 3.25 - vip_penalty * 0.8

	# Shift 2 is the complete game's decisive celebrity case. Its newspaper is
	# also the final result screen, so the outcome deliberately overwhelms the
	# smaller per-encounter adjustments.
	if report_day == 2:
		if ven_inside_death or ven_outside_death:
			GameState.reputation = 0.0
			GameState.share_price = 1.0
			reputation_change = GameState.reputation - starting_reputation
			share_change = ((GameState.share_price - starting_share_price) / maxf(starting_share_price, 0.01)) * 100.0
			%Headline.text = "GAME OVER — NIGHTHAVEN CLOSES PERMANENTLY"
			%Subheadline.text = "Ven Keer's death destroys public trust; collapsing shares force the hotel to close"
			%BreakdownTitle.text = "FINAL VERDICT — THE CELEBRITY WAS NOT SAVED"
		else:
			GameState.reputation = 100.0
			GameState.share_price = maxf(100.0, starting_share_price * 2.5)
			reputation_change = GameState.reputation - starting_reputation
			share_change = ((GameState.share_price - starting_share_price) / maxf(starting_share_price, 0.01)) * 100.0
			%Headline.text = "YOU WON — VEN KEER SAVED"
			%Subheadline.text = "Congratulations! Your decisions protected the celebrity and sent NightHaven's reputation and shares soaring"
			%BreakdownTitle.text = "VICTORY — NIGHTHAVEN'S FUTURE IS SECURE"
	else:
		GameState.reputation = clampf(GameState.reputation + reputation_change, 0.0, 100.0)
		GameState.share_price = maxf(1.0, GameState.share_price + share_change)
	%ReputationValue.text = "%d / 100" % int(GameState.reputation)
	%ShareValue.text = "$%.2f" % GameState.share_price
	_set_metric_change(%ReputationDelta, reputation_change, "")
	_set_metric_change(%ShareDelta, share_change, "%")


func _get_result_details(encounter_id: String, succeeded: bool, story_flags: Dictionary) -> String:
	match encounter_id:
		"ethan_cole":
			return "Room 410 companion record exposed the stolen reservation card." if succeeded else "A stolen card holder gained access to Room 410."
		"ven_keer":
			if bool(story_flags.get("ven_inside_death", false)):
				return "Initially admitted, then killed inside Room 412 after the visitor breach."
			if bool(story_flags.get("ven_outside_death", false)):
				return "Rejected during synchronization and killed outside the shelter."
			return "The operator trusted the live logbook and restored VIP access."
		"caleb":
			return "Communication History exposed the Albany/Denver contradiction." if succeeded else "The impersonator reached Ven's room."
	return "Handled safely using the available evidence." if succeeded else "The decision caused a serious consequence."


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
