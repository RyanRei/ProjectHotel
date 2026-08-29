class_name WallClockController
extends Node3D

## Drives the imported wall-clock hands from the shared in-game clock.
## The model's hands rotate around their local Y axes, clockwise from 12 o'clock.

@export var hour_hand_name: StringName = &"hours_1"
@export var minute_hand_name: StringName = &"minutes_2"

var _hour_hand: Node3D
var _minute_hand: Node3D


func _ready() -> void:
	_hour_hand = find_child(str(hour_hand_name), true, false) as Node3D
	_minute_hand = find_child(str(minute_hand_name), true, false) as Node3D

	if _hour_hand == null or _minute_hand == null:
		push_error("WallClockController could not find the clock hand nodes.")
		set_process(false)
		return

	TimeManager.time_updated.connect(_on_time_updated)
	_update_hands(TimeManager.get_hour(), TimeManager.get_minute())


func _on_time_updated(hour: int, minute: int) -> void:
	_update_hands(hour, minute)


func _update_hands(hour: int, minute: int) -> void:
	# One full minute-hand turn per hour. The hour hand also advances gradually
	# with the minutes instead of snapping only on the hour.
	_minute_hand.rotation.y = -TAU * (float(minute) / 60.0)
	_hour_hand.rotation.y = -TAU * (float(hour % 12) / 12.0 + float(minute) / 720.0)
