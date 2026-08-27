class_name EncounterData
extends Resource

@export var name: String
@export_enum("INNOCENT", "KILLER") var caller_type: String
@export var dialogue: DialogueNode
@export var model:PackedScene
@export_enum("RESIDENT","VISITOR") var communication_type:String
@export_enum("SUCCESS","FAIL","TBD") var status:String="TBD"


@export var LogData:Dictionary={
	
}
