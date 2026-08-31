class_name DialogueChoiceButton
extends Button

var choice: DialogueChoice
var recommended := false

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


func set_recommended(value: bool) -> void:
	recommended = value
	var base_style := get_theme_stylebox("normal") as StyleBoxFlat
	if base_style == null:
		return
	var style := base_style.duplicate() as StyleBoxFlat
	style.border_color = Color("69b7a5") if value else Color("47595c")
	style.set_border_width_all(3 if value else 2)
	for state in [&"normal", &"hover", &"focus"]:
		add_theme_stylebox_override(state, style)
