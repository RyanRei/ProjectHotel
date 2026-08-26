extends Node
signal dialogue_started
signal dialogue_finished

var current_node: DialogueNode
var active := false

func start_dialogue(start_node: DialogueNode):
	print("check2")
	current_node = start_node
	active = true
	play_current_node()

func play_current_node():
	print("check3")
	dialogue_started.emit(current_node)
	pass
	#DialogueUI.show_node(current_node)

func advance():
	match current_node.final_choice:
		"ACCEPT":
			return end_dialogue("ACCEPT")
		"REJECT":
			return end_dialogue("REJECT")
			
	if not current_node.choices.is_empty():
		return

	if current_node.next_node:
		current_node = current_node.next_node
		play_current_node()
	else:
		end_dialogue("NORMAL")
		
func choose(index: int):
	var choice = current_node.choices[index]

	current_node = choice.next_node
	play_current_node()
	
func end_dialogue(final_choice:String):
	active = false
	dialogue_finished.emit()
