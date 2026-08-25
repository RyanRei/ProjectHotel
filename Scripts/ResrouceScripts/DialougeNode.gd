class_name DialogueNode
extends Resource
@export var voiceline:AudioStream
@export_multiline var text: String
@export var duration:float
@export var next_node:DialogueNode
@export var choices: Array[DialogueChoice]
