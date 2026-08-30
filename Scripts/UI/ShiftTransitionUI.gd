class_name ShiftTransitionUI
extends Control

@onready var title: Label = %Title
@onready var line: ColorRect = %Line


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func play_shift_intro(shift_number: int) -> void:
	visible = true
	modulate.a = 0.0
	title.text = "SHIFT %d BEGINS" % shift_number
	title.scale = Vector2(0.84, 0.84)
	line.scale.x = 0.0
	var intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.tween_property(self, "modulate:a", 1.0, 0.35)
	intro.parallel().tween_property(title, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(line, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	intro.tween_interval(1.35)
	intro.tween_property(self, "modulate:a", 0.0, 0.4)
	await intro.finished
	visible = false
