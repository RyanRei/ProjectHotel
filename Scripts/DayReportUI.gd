class_name DayReportUI
extends Control

signal report_closed

@onready var newspaper: NewspaperReport2D = $NewspaperReport2D


func _ready() -> void:
	add_to_group("day_report_ui")
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		newspaper.handle_primary_action()
		accept_event()


func show_report(report: Dictionary) -> void:
	visible = true
	await newspaper.show_report(report)
	visible = false
	report_closed.emit()
