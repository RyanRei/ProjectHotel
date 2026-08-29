extends Node

## The in-game clock for Project Hotel.
## Shift runs from 18:00 (6 PM) to 06:00 (6 AM) = 43,200 in-game seconds.
## Time scale controls how fast in-game seconds tick relative to real seconds.

signal time_updated(hour: int, minute: int)
signal shift_ended

const SHIFT_DURATION := 43200.0  # 12 hours in seconds
const SCALE_NORMAL := 2000.0     # when 600  10 in-game minutes per 1 real second- 
const SCALE_ENCOUNTER := 1.0    # Real-time during encounters
const SCALE_PAUSED := 0.0       # Frozen

## Seconds elapsed since 18:00 (shift start).
var in_game_seconds := 0.0
## Current time multiplier applied each frame.
var time_scale := SCALE_PAUSED

var _last_emitted_minute := -1


func _process(delta: float) -> void:
	if time_scale <= 0.0:
		return

	in_game_seconds += delta * time_scale
	in_game_seconds = minf(in_game_seconds, SHIFT_DURATION)

	var current_minute := get_minute()
	var current_hour := get_hour()
	if current_minute != _last_emitted_minute:
		_last_emitted_minute = current_minute
		time_updated.emit(current_hour, current_minute)

	if in_game_seconds >= SHIFT_DURATION:
		pause()
		shift_ended.emit()


# ── Time scale helpers ──────────────────────────────────────────────

func pause() -> void:
	time_scale = SCALE_PAUSED

func resume_normal() -> void:
	time_scale = SCALE_NORMAL

func resume_encounter() -> void:
	time_scale = SCALE_ENCOUNTER


# ── Clock read helpers ──────────────────────────────────────────────

## Returns the current in-game hour in 24h format (18–23, 0–6).
func get_hour() -> int:
	var absolute_seconds := int(in_game_seconds) + 18 * 3600  # offset from midnight
	var wrapped := absolute_seconds % 86400                    # wrap at 24h
	@warning_ignore("integer_division")
	return wrapped / 3600

## Returns the current in-game minute (0–59).
func get_minute() -> int:
	var absolute_seconds := int(in_game_seconds) + 18 * 3600
	var wrapped := absolute_seconds % 86400
	@warning_ignore("integer_division")
	return (wrapped % 3600) / 60

## Formatted time string, e.g. "6:50 PM" or "12:24 AM".
func get_time_string() -> String:
	var h := get_hour()
	var m := get_minute()
	var suffix := "AM" if h < 12 else "PM"
	var display_hour := h % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, m, suffix]


# ── Clock write helpers ─────────────────────────────────────────────

## Jump the clock to an absolute 24h time (e.g. set_time(18, 0) = 6 PM).
## Handles the PM→AM wrap: hours 18–23 and 0–6 are valid shift hours.
func set_time(hour: int, minute: int) -> void:
	in_game_seconds = clampf(get_total_seconds_for(hour, minute), 0.0, SHIFT_DURATION)
	_last_emitted_minute = get_minute()
	time_updated.emit(get_hour(), get_minute())

## Convert a 24h time to seconds-since-6PM.
## 18:00 → 0, 23:59 → 21540, 0:00 → 21600, 6:00 → 43200.
func get_total_seconds_for(hour: int, minute: int) -> float:
	hour = clampi(hour, 0, 23)
	minute = clampi(minute, 0, 59)
	var seconds_from_midnight := hour * 3600 + minute * 60
	var seconds_from_6pm := seconds_from_midnight - 18 * 3600
	if seconds_from_6pm < 0:
		seconds_from_6pm += 86400  # wrap past midnight
	return float(seconds_from_6pm)

## True when the clock has reached or passed 6:00 AM.
func is_shift_over() -> bool:
	return in_game_seconds >= SHIFT_DURATION
