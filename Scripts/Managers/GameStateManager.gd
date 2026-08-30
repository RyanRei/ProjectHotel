extends Node

var story_flags: Dictionary = {}
var reputation := 80.0
var share_price := 42.0

@export var day:int=1
@export var encounter:int=1

## True when camera movement, WASD movement, and 3D desk interactions own input.
## Dialogue and other keyboard HUDs temporarily set this to false.
var desk_state := true


func enter_desk_state() -> void:
	desk_state = true


func leave_desk_state() -> void:
	desk_state = false
