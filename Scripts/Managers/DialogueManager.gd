extends Node
signal dialogue_started
signal dialogue_finished(choice:String)
signal choices_requested(choices: Array[DialogueChoice])
var current_chosen:int
var current_node: DialogueNode
var active := false

func start_dialogue(start_node: DialogueNode):
	current_chosen=0
	current_node = start_node
	active = true
	play_current_node()

func play_current_node():
	dialogue_started.emit(current_node)
	pass
	#DialogueUI.show_node(current_node)

func advance():
	match current_node.final_choice:
		"ACCEPT":
			return end_dialogue("ACCEPT")
		"REJECT":
			return end_dialogue("REJECT")
			
		"QUESTION":
			
			if not current_node.choices.is_empty():
			
				choices_requested.emit(current_node.choices)
				return
			
	if current_node.next_node:
		current_node = current_node.next_node
		play_current_node()
	else:
		end_dialogue("NORMAL")
		
func choose(choice: DialogueChoice):
	current_chosen+=1
	var choices=current_node.choices
	choices.erase(choice)
	#print(current_chosen)
	if current_chosen<2:
		choice.next_node.choices=choices
	
	current_node = choice.next_node
	play_current_node()
	
func end_dialogue(final_choice:String):
	active = false
	dialogue_finished.emit(final_choice)
