extends Control
@onready var text_label: Label = $Subtitles
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	DialogueManager.dialogue_started.connect(run_dialogue)
	print("Connected")


func run_dialogue(current_node:DialogueNode):
	print("check4")
	show_line(current_node.text)
	
	audio_stream_player.stream=current_node.voiceline
	audio_stream_player.play()
	var duration = audio_stream_player.stream.get_length()
	
	#timer.wait_time=current_node.duration
	timer.wait_time=duration+0.3
	timer.start()
	
	await timer.timeout
	await hide_line().finished
	DialogueManager.advance()
	pass

func show_line(text:String):
	print(text)
	text_label.text = text
	text_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(text_label, "modulate:a", 1.0, 1)

func hide_line():
	var tween = create_tween()
	tween.tween_property(text_label, "modulate:a", 0.0, 0.6)
	return tween

#
#func change_line(text: String):
	#var tween = create_tween()
	#tween.tween_property(text_label, "modulate:a", 0.0, 0.2)
	#await tween.finished
#
	#text_label.text = text
#
	#tween = create_tween()
	#tween.tween_property(text_label, "modulate:a", 1.0, 0.2)
