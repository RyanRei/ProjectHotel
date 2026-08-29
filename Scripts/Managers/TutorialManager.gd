class_name TutorialManager
extends Node

@export var dialog_tutorial: Control
@export var camera:DeskCameraController
#@export var introduction_2d: Control
#@export var introduction_3d: Control
@export var phone_light:SpotLight3D
@export var logbook_light:SpotLight3D
@export var pc_light:SpotLight3D
@export var clock_light:SpotLight3D

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
	label.text="Who you are, where you are ahh
"
	await mouse_clicked
	label.text="Six PM. Shift starts. You're the night operator for XXXXXX Co. 
	Access Cards may get lost or damaged. When that happens, there's exactly one way back into their rooms, and THAT is YOUR whole job. 
	"
	await mouse_clicked
	label.text="Your shift runs from 6 PM to 6 AM. Rooms close for check-out at 10 and, well, anyone calling in after that better have a very good reason
	"
	await mouse_clicked
	label.text="Every decision you make tonight gets read out tomorrow morning in the daily “xxxx”. If you let the wrong person in, the resident dies. Turn away the right person, they die too except just outside instead of in. Either way, the company's numbers move up and down. Enough bad mornings, and the shelter crashes to an end.
	So. Let's get you prepared for the first call"
	await mouse_clicked
	label.text="Lets take a look with help of a walkthrough"
	await mouse_clicked
	dialog_tutorial.hide()
	get_tree().paused = false
	#await introduce_logbook()
	
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
