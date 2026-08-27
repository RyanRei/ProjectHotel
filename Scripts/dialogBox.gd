extends Control
@onready var text_label: Label = $Subtitles
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@export var accept_reject:AcceptRejectButton


func _ready() -> void:
	DialogueManager.dialogue_started.connect(run_dialogue)
	DialogueManager.choices_requested.connect(show_choices)


func run_dialogue(current_node:DialogueNode):

	show_line(current_node.text)
	
	audio_stream_player.stream=current_node.voiceline
	audio_stream_player.play()
	var duration = audio_stream_player.stream.get_length()
	
	#timer.wait_time=current_node.duration
	timer.wait_time=duration+0.3
	timer.start()
	
	await timer.timeout
	await hide_line().finished
	
	if current_node.wait_for_prompt:
		if current_node.next_node:
			accept_reject.turnOn(true)
		else:
			accept_reject.turnOn(false)
		var choiceMade:String=await accept_reject.choiceMade
		current_node.final_choice=choiceMade
		accept_reject.turnOff()
	DialogueManager.advance()
	pass

func show_line(text:String):
	
	text_label.text = text
	text_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(text_label, "modulate:a", 1.0, 1)

func hide_line():
	var tween = create_tween()
	tween.tween_property(text_label, "modulate:a", 0.0, 0.6)
	return tween









var dialogue_choices: Array[DialogueChoice]
var selected_choice := 0


func show_choices(choices: Array[DialogueChoice]):
	dialogue_choices = choices
	selected_choice = 0
	$Choices.show()

	for child in $Choices.get_children():
		child.queue_free()

	for choice in choices:
		var panel := PanelContainer.new()
		var label := Label.new()

		label.text = choice.text
		label.add_theme_font_size_override("font_size", 30)
		panel.add_child(label)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		panel.add_theme_stylebox_override("panel", style)

		$Choices.add_child(panel)

	update_choice_display()
	
func _input(event):
	if not $Choices.visible:
		return

	if event.is_action_pressed("Move Up"):
		selected_choice = max(0, selected_choice - 1)
		update_choice_display()

	elif event.is_action_pressed("Move Down"):
		selected_choice = min(dialogue_choices.size() - 1, selected_choice + 1)
		update_choice_display()

	elif event.is_action_pressed("Confirm"):
		var choice = dialogue_choices[selected_choice]
		$Choices.hide()
		DialogueManager.choose(choice)
		
func update_choice_display():
	for i in dialogue_choices.size():
		var panel: PanelContainer = $Choices.get_child(i)
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()

		if i == selected_choice:
			style.bg_color = Color(0.384, 0.384, 0.384, 0.9)
		else:
			style.bg_color = Color(0.1, 0.1, 0.1, 0.8)

		panel.add_theme_stylebox_override("panel", style)
			
			

#func show_choices(choices: Array[DialogueChoice]):
	#for child in $Choices.get_children():
		#child.queue_free()
#
	#for choice in choices:
		#var button := Button.new()
		#button.text = choice.text
		#$Choices.add_child(button)
#
		#button.pressed.connect(_on_choice_pressed.bind(choice))
#
#func _on_choice_pressed(choice: DialogueChoice):
	#$Choices.hide()
	#DialogueManager.choose(choice)
