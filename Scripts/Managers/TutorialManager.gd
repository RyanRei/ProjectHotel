class_name TutorialManager
extends Node

@export var dialog_tutorial: Control
#@export var introduction_2d: Control
#@export var introduction_3d: Control


signal mouse_clicked
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_clicked.emit()


func welcome():
	print("hijidjeidej")
	get_tree().paused = true
	var label:Label=dialog_tutorial.get_node("Panel/Label")
	print("kkkkk")
	dialog_tutorial.show()
	label.text="text1"
	await mouse_clicked
	label.text="text2"
	await mouse_clicked
	dialog_tutorial.hide()
	get_tree().paused = false
#
#func introduce_logbook():
	#get_tree().paused = true
	#introduction_2d.show()
	#await introduction_2d.clicked
	#introduction_2d.hide()
	#get_tree().paused = false
#
#func introduce_phone():
	#get_tree().paused = true
	#introduction_3d.show()
	#await introduction_3d.clicked
	#introduction_3d.hide()
	#get_tree().paused = false
