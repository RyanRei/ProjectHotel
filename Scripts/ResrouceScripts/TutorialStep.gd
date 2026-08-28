class_name TutorialAction
extends Resource

enum ActionType {
	HIGHLIGHT,
	ATTACH,
	WAIT,
	SHOW,
	HIDE
}

@export var type: ActionType
@export var target: NodePath
@export_multiline var text: String
