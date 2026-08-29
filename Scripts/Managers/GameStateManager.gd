extends Node

@export var day:int=1
@export var encounter:int=1

## True when camera movement, WASD movement, and 3D desk interactions own input.
## Dialogue and other keyboard HUDs temporarily set this to false.
var desk_state := true


func enter_desk_state() -> void:
	desk_state = true


func leave_desk_state() -> void:
	desk_state = false
