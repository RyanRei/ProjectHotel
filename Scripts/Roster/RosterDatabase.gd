class_name RosterDatabase
extends RefCounted

var residents: Array[ResidentRecord] = []
var visitors: Array[Dictionary] = []
var rooms: Array[Dictionary] = []


func _init() -> void:
	for spec in Shift1Data.resident_specs():
		residents.append(ResidentRecord.new(
			spec.room, spec.name, spec.check_in, spec.checkout, spec.status,
			spec.dob, spec.id_type, spec.id, spec.phone
		))
	visitors = Shift1Data.visitor_records()
	rooms = Shift1Data.room_records()


func get_records(tab_name: String) -> Array[Dictionary]:
	match tab_name:
		"VISITORS":
			return visitors
		"ROOMS":
			return get_room_records()
		_:
			return get_resident_records()


func get_resident_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for resident in residents:
		var room_status := "IN SYNC" if resident.room == "112" and is_sync_window() else "CURRENT"
		var companion := "Michael Turner" if resident.resident_name == "Daniel Reeves" else "Daniel Reeves" if resident.resident_name == "Michael Turner" else "None"
		records.append({
			"title":resident.resident_name.to_upper(),
			"summary":"ROOM %s  -  %s" % [resident.room, resident.status.to_upper()],
			"status":resident.status,
			"fields":[
				["ROOM", resident.room], ["ROOM STATUS", room_status], ["ROOM COMPANION", companion],
				["DATE OF BIRTH", resident.date_of_birth], ["CHECK-IN", resident.check_in],
				["CHECKOUT", resident.checkout], ["ID TYPE", resident.id_type],
				["ID ENDING", resident.id_ending], ["PHONE ENDING", resident.phone_ending],
			],
		})
	return records


func get_room_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for source in rooms:
		var record: Dictionary = source.duplicate(true)
		if bool(record.get("syncs", false)) and is_sync_window():
			record.status = "IN SYNC"
			record.summary = "%s  -  IN SYNC" % record.title
			record.fields.append(["SYNC UPDATE", get_sync_update(str(record.title))])
		records.append(record)
	return records


func get_sync_update(room_title: String) -> String:
	if room_title == "ROOM 112":
		return "Relocation review: radiator fault; room release pending"
	return "Room inventory and occupancy record updating"


func is_sync_window() -> bool:
	return TimeManager.get_hour() == 0


func search_records(tab_name: String, query: String) -> Array[Dictionary]:
	var normalized := query.strip_edges().to_lower()
	var results: Array[Dictionary] = []
	for record in get_records(tab_name):
		var searchable := (str(record.title) + " " + str(record.summary) + " " + str(record.status)).to_lower()
		for field in record.fields:
			searchable += " " + str(field[0]).to_lower() + " " + str(field[1]).to_lower()
		if normalized.is_empty() or searchable.contains(normalized):
			results.append(record)
	return results


func search(query: String) -> Array[ResidentRecord]:
	var results: Array[ResidentRecord] = []
	for resident in residents:
		if resident.matches(query):
			results.append(resident)
	return results


func get_by_room(room_number: String) -> ResidentRecord:
	for resident in residents:
		if resident.room == room_number:
			return resident
	return null
