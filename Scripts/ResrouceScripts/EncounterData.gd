class_name EncounterData
extends Resource

@export var name: String
@export_enum("Innocent", "Killer", "Visitor") var caller_type: String
@export var dialogue: DialogueNode
@export var model:PackedScene
@export_enum("CALL","ONSITE") var communication_type:String
