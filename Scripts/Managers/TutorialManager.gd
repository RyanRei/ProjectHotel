class_name TutorialManager
extends Node

@export var encounterManager:EncounterManager
@export var clock:WallClockController
@export var computahUi:RosterUI
@export var computah:ComputerMonitor
@export var dialog_tutorial: Control
@export var camera:DeskCameraController
@export var phone_light:SpotLight3D
@export var logbook_light:SpotLight3D
@export var pc_light:SpotLight3D
@export var clock_light:SpotLight3D
@export var panelTexts:Control
@export var logBook:LogbookController
@export var loggBookUi:LogbookUI
@export var pointer:TutorialPointer3D
#@export var logbookTutorial:Control
@export var phone_tutorial:Control
@export var phone:Phone
@export var normal_lights:Node3D
@export var world_dimmer:CanvasLayer
@export  var tab_explanation:Control
@export var accept_reject_buttons:AcceptRejectButton
@export var dialogBox:DialogBox

var question_asked:=1
var should_check_tab := false
var check_tab_button_active := false

signal mouse_clicked
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_clicked.emit()


func welcome():
	
	world_dimmer.show()
	get_tree().paused = true
	#var label:Label=dialog_tutorial.get_node("Panel/Label")
	
	var label= tab_explanation.get_node("opening/PanelContainer/Label")
	#dialog_tutorial.show()
	tab_explanation.get_node("opening").show()
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
	tab_explanation.get_node("opening").hide()
	get_tree().paused = false
	world_dimmer.hide()
	await introduce_logbook()
	
#
func introduce_logbook():
	normal_lights.hide()
	#get_tree().paused = true
	logbook_light.show()
	#var label:Label=tab_explanation.get_node("introduceLogbook/PanelTexts/PanelContainer/Label").show()
	#label.text=""
	#panelTexts.show()
	#label.text="Click to open the logbook ah"
	tab_explanation.get_node("introduceLogbook").show()
	pointer.point_at(logBook)
	await logBook.logbook_clicked
	world_dimmer.show()
	logbook_light.hide()
	tab_explanation.get_node("introduceLogbook").hide()
	loggBookUi.logBookClosable=false
	pointer.hide_pointer()
	
	var logbookleft:Control=tab_explanation.get_node("logbookleft")
	logbookleft.show()
	await mouse_clicked
	logbookleft.hide()
	var logbookright:Control=tab_explanation.get_node("logbookright")	
	logbookright.show()
	await mouse_clicked
	logbookright.hide()
	
	loggBookUi.logBookClosable=true
	loggBookUi.close_logbook()
	
	logbook_light.hide()
	normal_lights.show()
	world_dimmer.hide()

	
	
	
	

func introduce_phone():
	normal_lights.hide()
	#get_tree().paused = true
	phone_light.show()
	logbook_light.hide()
	#var label:Label=phone
	phone_tutorial.show()
	pointer.point_at(phone)
	
	await phone.call_answered
	phone_tutorial.hide()
	pointer.hide_pointer()
	
	phone_light.hide()
	normal_lights.show()
	
	
func introduce_tabs():
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	
	tab_explanation.get_node("acceptReject").show()
	
	await mouse_clicked
	tab_explanation.get_node("acceptReject").hide()
	tab_explanation.get_node("question").show()
	accept_reject_buttons.unlock_question()
	await accept_reject_buttons.sendqn
	tab_explanation.get_node("question").hide()

	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	#accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()

func select_question():
	
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	dialogBox.lock_move_down()
	dialogBox.lock_move_down()

	tab_explanation.get_node("q1tracey").show()
	await dialogBox.confirmqn
	tab_explanation.get_node("q1tracey").hide()
	
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	should_check_tab = true
	world_dimmer.hide()

func check_tab_button():
	world_dimmer.show()
	check_tab_button_active = true
	dialogBox.tutorial_check_tab_active = true
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()
	#dialogBox.lock_toggle_hud()
	
	tab_explanation.get_node("checktab").show()
	await dialogBox.tab_checked
	tab_explanation.get_node("checktab").hide()
	check_tab_button_active = false
	should_check_tab = false
	dialogBox.tutorial_check_tab_active = false
	
	# unlock only after the tutorial has actually observed the Tab press
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.lock_toggle_hud()
	world_dimmer.hide()
	check_computer_click()

func check_computer_click():
	
	pointer.point_at(computah)

	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()
	dialogBox.lock_toggle_hud()

	await computah.computer_clicked
	tab_explanation.get_node("itmatches").show()
	world_dimmer.show()

	await computahUi.computah_closed

	if tab_explanation.has_node("itmatches"):
		tab_explanation.get_node("itmatches").hide()

	await get_tree().create_timer(0.25).timeout

	pointer.hide_pointer()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()
	
	
func introduce_clock():
	normal_lights.hide()
	clock_light.show()
	tab_explanation.get_node("clockticks").show()
	pointer.point_at(clock)
	
	await encounterManager.sendClockFinished
	tab_explanation.get_node("clockticks").hide()
	pointer.hide_pointer()
	
	clock_light.hide()
	normal_lights.show()
	
	
#ENCOUNTER 1 ENDED, NOW START 2
	
func enc2QuestionPointer():
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	print("question")
	tab_explanation.get_node("ENC2/questionPointer").show()
	accept_reject_buttons.unlock_question()
	await accept_reject_buttons.sendqn
	tab_explanation.get_node("ENC2/questionPointer").hide()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	#accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()


func enc2SelectQuestion():
	
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()

	tab_explanation.get_node("ENC2/q1daniel").show()
	await dialogBox.confirmqn
	tab_explanation.get_node("ENC2/q1daniel").hide()
	
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	#should_check_tab = true
	world_dimmer.hide()


func e2_check_tab_button():
	world_dimmer.show()
	check_tab_button_active = true
	dialogBox.tutorial_check_tab_active = true
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()
	#dialogBox.lock_toggle_hud()
	
	tab_explanation.get_node("ENC2/checktab").show()
	await dialogBox.tab_checked
	tab_explanation.get_node("ENC2/checktab").hide()
	check_tab_button_active = false
	should_check_tab = false
	dialogBox.tutorial_check_tab_active = false
	
	# unlock only after the tutorial has actually observed the Tab press
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.lock_toggle_hud()
	world_dimmer.hide()
	check_logBook_click()
	
func check_logBook_click():
	
	pointer.point_at(logBook)

	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_move_up()
	dialogBox.lock_move_down()
	dialogBox.lock_confirm()
	dialogBox.lock_toggle_hud()

	await logBook.logbook_clicked
	tab_explanation.get_node("ENC2/becareful").show()
	world_dimmer.show()

	await loggBookUi.logbookClosed
	


	tab_explanation.get_node("ENC2/becareful").hide()

	await get_tree().create_timer(0.25).timeout

	pointer.hide_pointer()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_cancel()
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_reject()
	dialogBox.unlock_move_up()
	dialogBox.unlock_move_down()
	dialogBox.unlock_confirm()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()
	
func mayaChenIntroduction(mayaChen):
	
	tab_explanation.get_node("ENC3/mayaChenIntro").show()
	pointer.point_at(mayaChen)
	await mouse_clicked
	tab_explanation.get_node("ENC3/mayaChenIntro").hide()
	pointer.hide_pointer()
	
	
func enc3QuestionPointer():
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	
	tab_explanation.get_node("ENC3/questionPointer").show()
	accept_reject_buttons.unlock_question()
	await accept_reject_buttons.sendqn
	tab_explanation.get_node("ENC3/questionPointer").hide()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	#accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	world_dimmer.hide()


func enc3SelectQuestion():
	
	world_dimmer.show()
	accept_reject_buttons.lock_accept()
	accept_reject_buttons.lock_cancel()
	accept_reject_buttons.lock_question()
	accept_reject_buttons.lock_reject()
	dialogBox.lock_toggle_hud()
	#dialogBox.lock_move_up()
	#dialogBox.lock_move_down()

	tab_explanation.get_node("ENC3/q1maya").show()
	await dialogBox.confirmqn
	tab_explanation.get_node("ENC3/q1maya").hide()
	
	accept_reject_buttons.unlock_question()
	accept_reject_buttons.unlock_accept()
	accept_reject_buttons.unlock_reject()
	accept_reject_buttons.unlock_cancel()
	dialogBox.unlock_toggle_hud()
	#dialogBox.unlock_move_up()
	#dialogBox.unlock_move_down()
	#should_check_tab = true
	world_dimmer.hide()
	
	
