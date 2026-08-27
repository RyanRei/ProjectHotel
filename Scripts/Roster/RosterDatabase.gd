class_name RosterDatabase
extends RefCounted

var residents: Array[ResidentRecord] = []
var visitors: Array[Dictionary] = []
var rooms: Array[Dictionary] = []
var access_logs: Array[Dictionary] = []


func _init() -> void:
	residents = [
		ResidentRecord.new("101", "Tracey Miller", "Aug 18, 6:42 PM", "Aug 27, 10:00 PM", "Occupied", "May 14, 1994", "Driver License", "4821", "7734"),
		ResidentRecord.new("102", "Sennet Cole", "Aug 25, 7:10 PM", "Aug 26, 9:00 PM", "Checked Out", "Nov 02, 1987", "National ID", "1906", "2418"),
		ResidentRecord.new("103", "William Hayes", "Aug 21, 5:35 PM", "Aug 29, 10:00 PM", "Occupied", "Jan 09, 1946", "Senior ID", "7312", "0965"),
		ResidentRecord.new("104", "Nina Patel", "Aug 26, 6:05 PM", "Aug 30, 10:00 PM", "Occupied", "Sep 23, 1991", "Driver License", "6054", "1183"),
		ResidentRecord.new("107", "Marcus Reed", "Aug 24, 8:15 PM", "Aug 28, 10:00 PM", "Away", "Mar 31, 1983", "Passport", "3589", "4207"),
	]
	visitors = [
		make_record("MAYA CHEN", "ROOM 101  •  APPROVED", "APPROVED", [
			["HOST", "Tracey Miller"], ["ROOM", "101"], ["ARRIVAL WINDOW", "8:30 PM - 9:15 PM"],
			["ID TYPE", "Driver License"], ["ID ENDING", "6621"], ["HOST PHONE ENDING", "7734"],
			["NOTE", "Resident called reception at 7:40 PM"],
		]),
		make_record("CLARA HAYES", "ROOM 103  •  APPROVED", "APPROVED", [
			["HOST", "William Hayes"], ["ROOM", "103"], ["ARRIVAL WINDOW", "10:15 PM - 11:00 PM"],
			["ID TYPE", "National ID"], ["ID ENDING", "4408"], ["RELATION", "Daughter"],
			["NOTE", "Speak clearly; host has impaired hearing"],
		]),
		make_record("DANIEL ORTIZ", "ROOM 104  •  PENDING", "PENDING", [
			["HOST", "Nina Patel"], ["ROOM", "104"], ["ARRIVAL WINDOW", "11:30 PM - 12:00 AM"],
			["ID TYPE", "Passport"], ["ID ENDING", "9184"], ["HOST PHONE ENDING", "1183"],
			["NOTE", "Verify arrival time and ID before entry"],
		]),
	]
	rooms = [
		make_record("ROOM 101", "TRACEY MILLER  •  OCCUPIED", "OCCUPIED", room_fields("Tracey Miller", "Aug 18, 6:42 PM", "Aug 27, 10:00 PM", "None")),
		make_record("ROOM 102", "VACANT  •  CHECKED OUT", "VACANT", room_fields("Sennet Cole", "Aug 25, 7:10 PM", "Aug 26, 9:00 PM", "Cleaning inspection pending")),
		make_record("ROOM 103", "WILLIAM HAYES  •  OCCUPIED", "OCCUPIED", room_fields("William Hayes", "Aug 21, 5:35 PM", "Aug 29, 10:00 PM", "Resident has impaired hearing")),
		make_record("ROOM 104", "NINA PATEL  •  OCCUPIED", "OCCUPIED", room_fields("Nina Patel", "Aug 26, 6:05 PM", "Aug 30, 10:00 PM", "None")),
		make_record("ROOM 107", "MARCUS REED  •  AWAY", "AWAY", room_fields("Marcus Reed", "Aug 24, 8:15 PM", "Aug 28, 10:00 PM", "Expected back after midnight")),
	]
	access_logs = [
		make_record("7:12 PM  •  ROOM 104", "NINA PATEL  •  RESIDENT ENTRY", "GRANTED", [
			["PERSON", "Nina Patel"], ["TYPE", "Resident"], ["ROOM", "104"], ["RESULT", "Access granted"], ["OPERATOR NOTE", "Access card accepted"],
		]),
		make_record("7:48 PM  •  ROOM 101", "HOST PRE-AUTHORIZATION", "RECORDED", [
			["HOST", "Tracey Miller"], ["VISITOR", "Maya Chen"], ["ROOM", "101"], ["RESULT", "Visitor added"], ["ARRIVAL WINDOW", "8:30 PM - 9:15 PM"],
		]),
		make_record("8:05 PM  •  ROOM 102", "UNKNOWN PERSON  •  NO ACTIVE HOST", "DENIED", [
			["CLAIMED NAME", "Sennet Cole"], ["TYPE", "Unverified"], ["ROOM", "102"], ["RESULT", "Access denied"], ["REASON", "Room checked out at 9:00 PM"],
		]),
	]


func make_record(title: String, summary: String, status: String, fields: Array) -> Dictionary:
	return {"title": title, "summary": summary, "status": status, "fields": fields}


func room_fields(occupant: String, check_in: String, checkout: String, note: String) -> Array:
	return [["ASSIGNED TO", occupant], ["CHECK-IN", check_in], ["CHECKOUT", checkout], ["ROOM TYPE", "Single shelter room"], ["SPECIAL NOTE", note]]


func get_records(tab_name: String) -> Array[Dictionary]:
	match tab_name:
		"VISITORS":
			return visitors
		"ROOMS":
			return rooms
		"ACCESS LOG":
			return access_logs
		_:
			var records: Array[Dictionary] = []
			for resident in residents:
				records.append({
					"title": resident.resident_name.to_upper(),
					"summary": "ROOM %s  •  %s" % [resident.room, resident.status.to_upper()],
					"status": resident.status,
					"fields": [
						["ROOM", resident.room], ["DATE OF BIRTH", resident.date_of_birth],
						["CHECK-IN", resident.check_in], ["CHECKOUT", resident.checkout],
						["ID TYPE", resident.id_type], ["ID ENDING", resident.id_ending],
						["PHONE ENDING", resident.phone_ending],
					],
				})
			return records


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
