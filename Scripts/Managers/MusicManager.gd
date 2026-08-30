extends Node

const MUSIC_VOLUME_DB := -9.0

var _player: AudioStreamPlayer
var _menu_music: AudioStreamMP3
var _gameplay_music: AudioStreamMP3
var _stress_music: AudioStreamWAV
var _transition: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_music = load("res://Assets/Audio/Music/MenuMusic.mp3") as AudioStreamMP3
	_gameplay_music = load("res://Assets/Audio/Music/Gameplay.mp3") as AudioStreamMP3
	_stress_music = load("res://Assets/Audio/Music/StressLoop.wav") as AudioStreamWAV
	_menu_music.loop = true
	_gameplay_music.loop = true
	_stress_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_player.volume_db = MUSIC_VOLUME_DB
	add_child(_player)
	_player.finished.connect(_restart_current_track)


func play_menu() -> void:
	_play_track(_menu_music)


func play_gameplay() -> void:
	_play_track(_gameplay_music)


func play_stress() -> void:
	if _player.stream == _stress_music and _player.playing:
		return
	if _transition and _transition.is_valid():
		_transition.kill()
	_transition = create_tween()
	_transition.tween_property(_player, "volume_db", -40.0, 0.45)
	_transition.tween_callback(_start_stress_track)
	# This fade runs only when the stress track is first selected. The WAV's
	# internal loop continues without invoking play_stress() or fading again.
	_transition.tween_property(_player, "volume_db", MUSIC_VOLUME_DB, 1.0)


func _start_stress_track() -> void:
	_player.stop()
	_player.stream = _stress_music
	_player.play()


func _play_track(track: AudioStreamMP3) -> void:
	if _transition and _transition.is_valid():
		_transition.kill()
	if _player.stream == track and _player.playing:
		_player.volume_db = MUSIC_VOLUME_DB
		return
	_player.stop()
	_player.stream = track
	_player.volume_db = MUSIC_VOLUME_DB
	_player.play()


func _restart_current_track() -> void:
	# AudioStreamMP3.loop normally handles this. This fallback keeps playback
	# continuous if an imported stream temporarily loses its loop flag.
	if _player.stream != null:
		_player.play()
