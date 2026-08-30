extends Node

const MUSIC_VOLUME_DB := -9.0

var _player: AudioStreamPlayer
var _menu_music: AudioStreamMP3
var _gameplay_music: AudioStreamMP3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_music = load("res://Assets/Audio/Music/MenuMusic.mp3") as AudioStreamMP3
	_gameplay_music = load("res://Assets/Audio/Music/Gameplay.mp3") as AudioStreamMP3
	_menu_music.loop = true
	_gameplay_music.loop = true
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


func _play_track(track: AudioStreamMP3) -> void:
	if _player.stream == track and _player.playing:
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
