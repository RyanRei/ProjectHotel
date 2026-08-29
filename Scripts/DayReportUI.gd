class_name DayReportUI
extends Control

signal report_closed

@onready var newspaper: NewspaperReport2D = $NewspaperReport2D


func _ready() -> void:
	visible = false


func show_report(report: Dictionary) -> void:
	visible = true
	await newspaper.show_report(report)
	visible = false
	report_closed.emit()
