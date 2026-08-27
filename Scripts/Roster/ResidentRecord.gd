class_name ResidentRecord
extends RefCounted

var room: String
var resident_name: String
var check_in: String
var checkout: String
var status: String
var date_of_birth: String
var id_type: String
var id_ending: String
var phone_ending: String


func _init(
	room_number: String,
	full_name: String,
	check_in_time: String,
	checkout_time: String,
	current_status: String,
	birth_date: String,
	identity_type: String,
	identity_ending: String,
	contact_ending: String
) -> void:
	room = room_number
	resident_name = full_name
	check_in = check_in_time
	checkout = checkout_time
	status = current_status
	date_of_birth = birth_date
	id_type = identity_type
	id_ending = identity_ending
	phone_ending = contact_ending


func matches(query: String) -> bool:
	var normalized := query.strip_edges().to_lower()
	return normalized.is_empty() \
		or room.to_lower().contains(normalized) \
		or resident_name.to_lower().contains(normalized) \
		or status.to_lower().contains(normalized)
