class_name DialogueNode
extends Resource
@export var voiceline:AudioStream
@export_multiline var text: String
@export var duration:float
@export var next_node:DialogueNode
@export var choices: Array[DialogueChoice]
@export var wait_for_prompt: bool=false
## Used by reveal/taunt calls where the player must choose a question but must
## not be offered an access decision.
@export var question_only_prompt: bool=false
## Prevents Confirm from fast-forwarding the typewriter or voice playback.
@export var unskippable: bool=false
## Advances after text and voice finish without showing the Continue indicator.
@export var auto_advance: bool=false
@export_enum("ACCEPT","REJECT","QUESTION","NORMAL") var final_choice:String="NORMAL"
