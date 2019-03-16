extends Node

func isMoveRightPressed()->bool:
	if Input.is_action_pressed("ui_right"):
		return true
	else: return false

func isMoveLeftPressed()->bool:
	if Input.is_action_pressed("ui_left"):
		return true
	else: return false

func isMoveDownPressed()->bool:
	if Input.is_action_pressed("ui_down"):
		return true
	else: return false

func isMoveDownRelease()->bool:
	if Input.is_action_just_released("ui_down"):
		return true
	else: return false

func isJumpPressed()->bool:
	if Input.is_action_pressed("ui_accept"):
		return true
	else: return false

func isJumpJustPressed()->bool:
	if Input.is_action_just_pressed("ui_accept"):
		return true
	else: return false

func isJumpRelease()->bool:
	if Input.is_action_just_released("ui_accept"):
		return true
	else: return false