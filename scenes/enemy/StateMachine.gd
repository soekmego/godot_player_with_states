extends Node

#Variables
var state = STATE.DEFAULT

#state machine options
enum STATE {
	DEFAULT, 
	SWORD_ATTACK_1, 
	SWORD_ATTACK_2, 
	SWORD_ATTACK_3, 
	KNOCKBACK
	}

func StateMachine(delta):
	pass