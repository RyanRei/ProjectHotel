class_name Shift2Data
extends RefCounted


static func resident_specs() -> Array[Dictionary]:
	return [
		{"room":"103", "name":"Ethan Cole", "check_in":"Aug 19, 5:08 PM", "checkout":"Sep 01, 10:00 AM", "status":"Occupied", "dob":"Mar 09, 1991", "id_type":"Reservation Card", "id":"5512", "phone":"6381", "companion":"Diana Webb"},
		{"room":"103", "name":"Diana Webb", "check_in":"Aug 19, 5:11 PM", "checkout":"Sep 01, 10:00 AM", "status":"Occupied", "dob":"Jul 21, 1992", "id_type":"Reservation Card", "id":"8846", "phone":"2019", "companion":"Ethan Cole"},
		{"room":"412", "name":"Ven Keer", "check_in":"Aug 31, 11:45 PM", "checkout":"Sunday, 10:00 AM", "status":"Occupied", "dob":"Oct 18, 1995", "id_type":"Reservation Card", "id":"4097", "phone":"1170", "companion":"None"},
		{"room":"207", "name":"Michael Turner", "check_in":"Aug 21, 7:12 PM", "checkout":"Sep 01, 10:00 AM", "status":"Occupied", "dob":"Feb 18, 1989", "id_type":"Reservation Card", "id":"7742", "phone":"6105", "companion":"Daniel Reeves"},
		{"room":"207", "name":"Daniel Reeves", "check_in":"Aug 21, 7:10 PM", "checkout":"Sep 01, 10:00 AM", "status":"Occupied", "dob":"Nov 02, 1987", "id_type":"Reservation Card", "id":"1906", "phone":"2418", "companion":"Michael Turner"},
	]


static func visitor_records() -> Array[Dictionary]:
	return [
		make_record("CALEB KEER", "ROOM 412  -  EXPECTED", "EXPECTED", [
			["HOST", "Ven Keer"], ["ROOM", "412"], ["ARRIVAL WINDOW", "Around 1:30 AM"],
			["RELATION", "Brother"], ["RESERVATION CARD", "None - visitor"],
			["NOTE", "Travel method not recorded in the computer"],
		]),
	]


static func room_records() -> Array[Dictionary]:
	return [
		room_record("103", "Ethan Cole / Diana Webb", "Occupied", "Aug 19, 5:08 PM", "Sep 01, 10:00 AM", "Shared reservation"),
		room_record("207", "Daniel Reeves / Michael Turner", "Occupied", "Aug 21, 7:10 PM", "Sep 01, 10:00 AM", "Shared reservation"),
		room_record("412", "Previous occupant: Lydia Shaw", "Stale", "Aug 27, 3:20 PM", "Aug 31, 9:40 PM", "Last updated 11:32 PM; live assignment synchronizing", true),
	]


static func logbook_schedule() -> Array[Dictionary]:
	return [
		log_entry(18, 0, "6:00 PM", "SHIFT 2", "--", "IN", "Shift opened. Communication History cleared for the new shift."),
		log_entry(23, 45, "11:45 PM", "Ven Keer", "412", "IN", "New VIP check-in. Keep a low profile; do not disclose his stay to press or other guests."),
	]


static func log_entry(hour: int, minute: int, time: String, person_name: String, room: String, entry_type: String, note: String) -> Dictionary:
	return {"hour":hour, "minute":minute, "row":[time, person_name, room, entry_type], "note":note}


static func make_record(title: String, summary: String, status: String, fields: Array) -> Dictionary:
	return {"title":title, "summary":summary, "status":status, "fields":fields}


static func room_record(room: String, occupant: String, status: String, check_in: String, checkout: String, note: String, syncs := false) -> Dictionary:
	return {"title":"ROOM " + room, "summary":"ROOM %s  -  %s  -  %s" % [room, occupant.to_upper(), status.to_upper()], "status":status, "syncs":syncs, "fields":[["ASSIGNED TO", occupant], ["CHECK-IN", check_in], ["CHECKOUT", checkout], ["ROOM TYPE", "Shelter room"], ["SPECIAL NOTE", note]]}
