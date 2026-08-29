class_name DialogueChoiceButton
extends Button

var choice: DialogueChoice

func set_choice(value: DialogueChoice) -> void:
	choice = value
	text = value.text

func set_selected(selected: bool) -> void:
	if selected:
		modulate = Color(1.0, 0.93, 0.61, 1.0)
		text = "> " + choice.text + " [F]"
	else:
		modulate = Color.WHITE
		text = choice.text
