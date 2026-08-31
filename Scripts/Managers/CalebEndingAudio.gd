class_name CalebEndingAudio
extends Node

const HANGUP_STREAM := preload("res://Assets/Sound/sfx/hangup.mp3")
const HEARTBEAT_STREAM := preload("res://Assets/Sound/sfx/heartbeat.wav")
const BREATHING_STREAM := preload("res://Assets/Sound/sfx/breathing.wav")
const DEAD_LINE_STREAM := preload("res://Assets/Sound/sfx/endcalldeadline.mp3")
const DEAD_LINE_GAP_SECONDS := 1.2

var _hangup: AudioStreamPlayer
var _heartbeat: AudioStreamPlayer
var _breathing: AudioStreamPlayer
var _dead_line: AudioStreamPlayer
var _active := false
var _generation := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hangup = _make_player("CalebHangup", HANGUP_STREAM, -3.0)
	_heartbeat = _make_player("CalebHeartbeat", HEARTBEAT_STREAM, -3.0)
	_breathing = _make_player("CalebBreathing", BREATHING_STREAM, -5.0)
	_dead_line = _make_player("CalebDeadLine", DEAD_LINE_STREAM, -11.0)


func start_sequence() -> void:
	if _active:
		return
	_active = true
	_generation += 1
	var run_generation := _generation
	MusicManager.fade_out(0.9)
	_hangup.play()
	while _hangup.playing and _active and run_generation == _generation:
		await get_tree().process_frame
	if not _active or run_generation != _generation:
		return
	_play_continuous_pattern(_heartbeat, run_generation)
	_play_continuous_pattern(_breathing, run_generation)
	_play_dead_line_pattern(run_generation)


func _play_continuous_pattern(player: AudioStreamPlayer, run_generation: int) -> void:
	while _active and run_generation == _generation:
		player.play()
		while player.playing and _active and run_generation == _generation:
			await get_tree().process_frame


func _play_dead_line_pattern(run_generation: int) -> void:
	while _active and run_generation == _generation:
		_dead_line.play()
		while _dead_line.playing and _active and run_generation == _generation:
			await get_tree().process_frame
		if not _active or run_generation != _generation:
			return
		await get_tree().create_timer(DEAD_LINE_GAP_SECONDS).timeout


func stop_sequence() -> void:
	_active = false
	_generation += 1
	for player in [_hangup, _heartbeat, _breathing, _dead_line]:
		if player != null:
			player.stop()


func _make_player(player_name: StringName, audio_stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = audio_stream
	player.volume_db = volume_db
	add_child(player)
	return player
