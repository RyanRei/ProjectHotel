extends Node
signal dialogue_started
signal dialogue_finished(choice:String)
signal choices_requested(choices: Array[DialogueChoice])
var current_chosen:int
var current_node: DialogueNode
var active := false
var current_speaker_name := ""

var current_active_choices: Array[DialogueChoice] = []

func start_dialogue(start_node: DialogueNode, speaker_name: String = ""):
	current_chosen=0
	current_node = start_node
	current_speaker_name = speaker_name
	active = true
	current_active_choices = current_node.choices.duplicate()
	play_current_node()

func play_current_node():
	if not current_node.choices.is_empty():
		current_active_choices = current_node.choices.duplicate()
	dialogue_started.emit(current_node)

func has_active_choices() -> bool:
	return not current_active_choices.is_empty()


func get_remaining_question_count() -> int:
	return mini(2 - current_chosen, current_active_choices.size())

func advance(choice_made: String = ""):
	var action = choice_made
	if action == "":
		action = current_node.final_choice
		
	match action:
		"ACCEPT":
			return end_dialogue("ACCEPT")
		"REJECT":
			return end_dialogue("REJECT")
		"QUESTION":
			if not current_active_choices.is_empty():
				choices_requested.emit(current_active_choices)
				return
			
	if current_node.next_node:
		current_node = current_node.next_node
		play_current_node()
	else:
		end_dialogue("NORMAL")
		
func choose(choice: DialogueChoice):
	current_chosen+=1
	current_active_choices.erase(choice)
	
	if current_chosen >= 2:
		current_active_choices.clear()
	
	current_node = choice.next_node
	play_current_node()
	
func end_dialogue(final_choice:String):
	active = false
	current_active_choices.clear()
	dialogue_finished.emit(final_choice)
