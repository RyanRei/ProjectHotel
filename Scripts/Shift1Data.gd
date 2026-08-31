class_name Shift1Data
extends RefCounted

## Static prototype data shared by the Shift 1 computer and logbook.

static func resident_specs() -> Array[Dictionary]:
	return [
		{"room":"104", "name":"Tracey Morgan", "check_in":"Aug 20, 4:35 PM", "checkout":"Sep 02, 10:00 AM", "status":"Occupied", "dob":"May 14, 1994", "id_type":"Driver License", "id":"4821", "phone":"7734"},
		{"room":"207", "name":"Daniel Reeves", "check_in":"Aug 21, 7:10 PM", "checkout":"Sep 01, 10:00 AM", "status":"Occupied", "dob":"Nov 02, 1987", "id_type":"National ID", "id":"1906", "phone":"2418"},
		{"room":"207", "name":"Michael Turner", "check_in":"Aug 21, 7:12 PM", "checkout":"Sep 01, 10:00 AM", "status":"Occupied", "dob":"Feb 18, 1989", "id_type":"Driver License", "id":"7742", "phone":"6105"},
		{"room":"112", "name":"Arthur Williams", "check_in":"Aug 19, 5:20 PM", "checkout":"Aug 31, 10:00 AM", "status":"Occupied", "dob":"Jan 09, 1946", "id_type":"Senior ID", "id":"7312", "phone":"0965"},
		{"room":"203", "name":"Elena Voss", "check_in":"Aug 30, 6:12 PM", "checkout":"Sep 03, 10:00 AM", "status":"Occupied", "dob":"Jun 11, 1990", "id_type":"Passport", "id":"5528", "phone":"1830"},
		{"room":"205", "name":"Nora Bell", "check_in":"Aug 24, 8:15 PM", "checkout":"Sep 02, 10:00 AM", "status":"Occupied", "dob":"Mar 31, 1983", "id_type":"Passport", "id":"3589", "phone":"4207"},
	]


static func visitor_records() -> Array[Dictionary]:
	return [
		make_record("MAYA CHEN", "ROOM 104  -  EXPECTED", "EXPECTED", [
			["HOST", "Tracey Morgan"], ["ROOM", "104"], ["ARRIVAL WINDOW", "10:15 PM - 10:45 PM"],
			["RELATION", "Former coworker"], ["ITEM", "Blue document folder"],
			["NOTE", "Tracey notified reception at 9:55 PM"],
		]),
		make_record("CLARA HAYES", "ROOM 203  -  APPROVED", "APPROVED", [
			["HOST", "Elena Voss"], ["ROOM", "203"], ["ARRIVAL WINDOW", "8:30 PM - 9:00 PM"],
			["ID TYPE", "National ID"], ["ID ENDING", "4408"],
		]),
		make_record("OWEN PRICE", "ROOM 205  -  PENDING", "PENDING", [
			["HOST", "Nora Bell"], ["ROOM", "205"], ["ARRIVAL WINDOW", "1:15 AM - 1:45 AM"],
			["NOTE", "Verify ID before entry"],
		]),
	]


static func room_records() -> Array[Dictionary]:
	return [
		room_record("102", "Vacant", "Vacant", "Aug 25, 7:10 PM", "Aug 30, 7:05 PM", "Checkout complete; cleaning pending"),
		room_record("104", "Tracey Morgan", "Occupied", "Aug 20, 4:35 PM", "Sep 02, 10:00 AM", "None"),
		room_record("112", "Arthur Williams", "Occupied", "Aug 19, 5:20 PM", "Aug 31, 10:00 AM", "Radiator fault; relocation and room release pending", true),
		room_record("203", "Elena Voss", "Occupied", "Aug 30, 6:12 PM", "Sep 03, 10:00 AM", "Checked in this shift"),
		room_record("204", "Vacant", "Vacant", "--", "--", "Inventory update processing", true),
		room_record("205", "Nora Bell", "Occupied", "Aug 24, 8:15 PM", "Sep 02, 10:00 AM", "Visitor expected after 1:00 AM"),
		room_record("207", "Daniel Reeves / Michael Turner", "Occupied", "Aug 21, 7:10 PM", "Sep 01, 10:00 AM", "Shared room"),
	]


static func logbook_rows() -> Array:
	return []


static func logbook_schedule() -> Array[Dictionary]:
	return [
		log_entry(18, 0, "6:00 PM", "Marcus Lane", "109", "OUT", ""),
		log_entry(18, 12, "6:12 PM", "Elena Voss", "203", "IN", ""),
		log_entry(18, 35, "6:35 PM", "Tracey Morgan", "104", "CALL", "Tracey Morgan called from the lobby phone and reported that her card may be inside Room 104."),
		log_entry(19, 5, "7:05 PM", "Sennet Cole", "102", "OUT", ""),
		log_entry(20, 40, "8:40 PM", "Room 205", "205", "CALL", ""),
		log_entry(20, 55, "8:55 PM", "Room 207", "207", "CALL", "Room 207 requested fresh towels. No card fault was reported for Daniel Reeves."),
		log_entry(21, 55, "9:55 PM", "Maya Chen", "104", "VIS", "Tracey Morgan notified reception that Maya Chen is expected between 10:15 PM and 10:45 PM."),
		log_entry(23, 48, "11:48 PM", "Arthur Williams", "112", "CALL", "Arthur Williams called reception from Room 112 about the radiator humming again. Maintenance was deferred until morning."),
	]


static func log_entry(hour: int, minute: int, time: String, person_name: String, room: String, entry_type: String, note: String) -> Dictionary:
	return {
		"hour":hour,
		"minute":minute,
		"row":[time, person_name, room, entry_type],
		"note":note,
	}


static func make_record(title: String, summary: String, status: String, fields: Array) -> Dictionary:
	return {"title":title, "summary":summary, "status":status, "fields":fields}


static func room_record(room: String, occupant: String, status: String, check_in: String, checkout: String, note: String, syncs := false) -> Dictionary:
	return {
		"title":"ROOM " + room,
		"summary":"ROOM %s  -  %s  -  %s" % [room, occupant.to_upper(), status.to_upper()],
		"status":status,
		"syncs":syncs,
		"fields":[
			["ASSIGNED TO", occupant], ["CHECK-IN", check_in], ["CHECKOUT", checkout],
			["ROOM TYPE", "Shelter room"], ["SPECIAL NOTE", note],
		],
	}
