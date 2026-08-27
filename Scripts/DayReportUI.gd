class_name DayReportUI
extends Control

signal report_closed

func _ready():
	visible = false
	$Newspaper/Content/CloseButton.pressed.connect(_on_close_button_pressed)

func show_report(report: Dictionary):
	visible = true
	$Newspaper/Content/DayLabel.text = "DAY %d REPORT" % report["day"]

	for child in $Newspaper/Content/Results.get_children():
		child.queue_free()

	for result in report["results"]:
		print(report["results"])
		var label := Label.new()
		label.text = "%s — %s" % [result.name, result.status]
		$Newspaper/Content/Results.add_child(label)

	await report_closed
	visible = false

func _on_close_button_pressed():
	report_closed.emit()
