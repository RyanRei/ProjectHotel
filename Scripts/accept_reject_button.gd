class_name AcceptRejectButton
extends Control

signal choiceMade(choice: String)
signal confirmation_requested(message: String)
signal confirmation_cancelled
var accept_locked := false
var reject_locked := false
var question_locked := false
var canceled_locked := false
#for tutorial
signal sendqn
signal sendaccept
signal sendreject
signal sendcancel


enum DecisionState {
	CHOOSING,
	CONFIRMING_ACCEPT,
	CONFIRMING_REJECT,
}

@export var accept: Button
@export var reject: Button
@export var question: Button
@export var questions_remaining: Label

var active := false
var questionActive := true
var decision_state := DecisionState.CHOOSING


func _ready() -> void:
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_buttons_disabled(true)


func _input(event: InputEvent) -> void:
	if not active or not visible or not event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("Cancel Decision"):
		if decision_state != DecisionState.CHOOSING:
			_cancel_confirmation()
			get_viewport().set_input_as_handled()
			return
		if canceled_locked:
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Question"):
		if question_locked:
			return
		if decision_state == DecisionState.CHOOSING and questionActive:
			sendqn.emit()
			choiceMade.emit("QUESTION")
			
			
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Accept"):
		if accept_locked:
			return
		_handle_accept()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Reject"):
		if reject_locked:
			return
		_handle_reject()
		get_viewport().set_input_as_handled()

func _handle_accept() -> void:
	if decision_state == DecisionState.CHOOSING:
		decision_state = DecisionState.CONFIRMING_ACCEPT
		accept.grab_focus()
		confirmation_requested.emit("Are you sure you want to let them in?\n[A] Confirm    [X] Go back")
	elif decision_state == DecisionState.CONFIRMING_ACCEPT:
		choiceMade.emit("ACCEPT")
	sendaccept.emit()


func _handle_reject() -> void:
	if decision_state == DecisionState.CHOOSING:
		decision_state = DecisionState.CONFIRMING_REJECT
		reject.grab_focus()
		confirmation_requested.emit("Are you sure you want to keep them out?\n[R] Confirm    [X] Go back")
	elif decision_state == DecisionState.CONFIRMING_REJECT:
		choiceMade.emit("REJECT")
	sendreject.emit()


func _cancel_confirmation() -> void:
	decision_state = DecisionState.CHOOSING
	accept.release_focus()
	reject.release_focus()
	confirmation_cancelled.emit()
	sendcancel.emit()


func is_confirming_decision() -> bool:
	return decision_state != DecisionState.CHOOSING


func turnOff() -> void:
	active = false
	decision_state = DecisionState.CHOOSING
	_set_buttons_disabled(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	accept.release_focus()
	reject.release_focus()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished


func turnOn(remaining_question_count: int) -> void:
	questionActive = remaining_question_count > 0
	question.get_parent().visible = questionActive
	questions_remaining.text = "(%d/2 remaining)" % remaining_question_count
	decision_state = DecisionState.CHOOSING
	visible = true
	active = true
	_set_buttons_disabled(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	await tween.finished


func _set_buttons_disabled(disabled: bool) -> void:
	accept.disabled = disabled
	reject.disabled = disabled
	question.disabled = disabled


func _on_accept_pressed() -> void:
	_handle_accept()


func _on_reject_pressed() -> void:
	_handle_reject()


func _on_question_pressed() -> void:
	if decision_state == DecisionState.CHOOSING and questionActive:
		choiceMade.emit("QUESTION")
		



#for tutorial
func lock_accept() -> void:
	accept_locked = true

func unlock_accept() -> void:
	accept_locked = false

func lock_reject() -> void:
	reject_locked = true

func unlock_reject() -> void:
	reject_locked = false

func lock_question() -> void:
	question_locked = true

func unlock_question() -> void:
	question_locked = false

func lock_cancel() -> void:
	canceled_locked = true

func unlock_cancel() -> void:
	canceled_locked = false
