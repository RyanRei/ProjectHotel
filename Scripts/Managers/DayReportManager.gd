#class_name DayReportManager
extends Node

signal report_ready(report: Dictionary)

var reports: Array[Dictionary] = []

func add_report(day: int, results: Array[Dictionary]) -> Dictionary:
	var report := {
		"day": day,
		"results": results.duplicate(true),
		"story_flags": GameState.story_flags.duplicate(true)
	}

	# A shift can be replayed repeatedly while testing without restarting the
	# application. Replace its cached report so get_report() never returns an
	# older, empty result from a previous run.
	var existing_index := -1
	for index in range(reports.size()):
		if int(reports[index].get("day", -1)) == day:
			existing_index = index
			break
	if existing_index >= 0:
		reports[existing_index] = report
	else:
		reports.append(report)
	report_ready.emit(report)
	return report


func get_report(day: int) -> Dictionary:
	for index in range(reports.size() - 1, -1, -1):
		var report := reports[index]
		if int(report.get("day", -1)) == day:
			return report
	return {}


func clear_reports() -> void:
	reports.clear()
