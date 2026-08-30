class_name EncounterData
extends Resource

@export var name: String
@export var encounter_id: String
@export_enum("INNOCENT", "KILLER") var caller_type: String
@export var dialogue: DialogueNode
@export var alternate_dialogue: DialogueNode
@export var model:PackedScene
@export_enum("RESIDENT","VISITOR","INFORMATIVE") var communication_type:String
@export_enum("MALE", "FEMALE") var visitor_gender: String = "MALE"
@export_enum("SUCCESS","FAIL","TBD") var status:String="TBD"
@export var time:String
@export var LogbookEntry:String
@export var reportable: bool = true
@export_range(1.0, 5.0, 0.5) var report_weight: float = 1.0
@export_group("Logbook")
@export var room_number: String
@export_enum("CALL", "VIS", "IN", "OUT") var logbook_type: String = "CALL"

@export_group("Schedule")
## Hour in 24h format when this encounter triggers (18-23 for PM, 0-6 for AM).
@export_range(0, 23) var trigger_hour: int = 18
## Minute when this encounter triggers.
@export_range(0, 59) var trigger_minute: int = 0

## Returns seconds elapsed since 6 PM for this encounter's trigger time.
func get_trigger_seconds() -> float:
	return TimeManager.get_total_seconds_for(trigger_hour, trigger_minute)
