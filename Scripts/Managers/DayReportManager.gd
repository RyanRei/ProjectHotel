#class_name DayReportManager
extends Node

signal report_ready(report: Dictionary)

var reports: Array[Dictionary] = []

func add_report(day: int, results: Array[Dictionary]):
	var report := {
		"day": day,
		"results": results.duplicate(true)
	}

	reports.append(report)
	report_ready.emit(report)


func get_report(day: int) -> Dictionary:
	for report in reports:
		if report.day == day:
			return report
	return {}
