class_name EncounterData
extends Resource

@export var name: String
@export_enum("INNOCENT", "KILLER") var caller_type: String
@export var dialogue: DialogueNode
@export var model:PackedScene
@export_enum("RESIDENT","VISITOR","INFORMATIVE") var communication_type:String
@export_enum("SUCCESS","FAIL","TBD") var status:String="TBD"
@export var time:String
@export var LogbookEntry:String

@export_group("Schedule")
## Hour in 24h format when this encounter triggers (18-23 for PM, 0-6 for AM).
@export_range(0, 23) var trigger_hour: int = 18
## Minute when this encounter triggers.
@export_range(0, 59) var trigger_minute: int = 0

## Returns seconds elapsed since 6 PM for this encounter's trigger time.
func get_trigger_seconds() -> float:
	return TimeManager.get_total_seconds_for(trigger_hour, trigger_minute)
