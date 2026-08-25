class_name EncounterData
extends Resource

@export var name: String
@export_enum("Innocent", "Killer", "Unknown") var caller_type: String
@export var dialogue: DialogueNode

@export_enum("CALL","ONSITE") var communication_type:String
