extends Node

#variables
var state = STATE.IDLE
var newActionTimer = 10
var target

#onready variables
onready var enemy = get_parent()

#State options
enum STATE {
	IDLE, 
	MOVE,
	ATTACK
	}

func stateMachine (delta):
	newActionTimer -= 1
	
	if state == STATE.IDLE:
		enemy.motion.x = 0
		enemy.anim.play("Idle")
		HandleGravity(delta)
		
	elif state == STATE.MOVE:
		HandleGravity(delta)
		enemy.anim.play("Run")
		HandleMoviment()
	
	elif state == STATE.ATTACK:
		state = STATE.MOVE
		pass

func HandleGravity(delta):
	enemy.motion.y += enemy.GRAVITY * delta

func HandleMoviment():
	if newActionTimer > 0:
		return
	
	if target == null:
		return
		
	var g_targetPos = target.get_global_position()
	var g_enemyPos = enemy.get_global_position()
	var sideValue = g_enemyPos.x - g_targetPos.x
	newActionTimer = 10
	
	if sideValue > 0:
		enemy.motion.x = -enemy.SPEED
		enemy.setDirection(-1)
	else:
		enemy.setDirection(1)
		enemy.motion.x = enemy.SPEED
		
	if abs(sideValue) > $MoveAreaTarget/CollisionShape2D.shape.get_radius():
		state = STATE.IDLE

func _on_MoveAreaTarget_body_entered(body):
	if body.get("TYPE") == "Player":
		state = STATE.MOVE
		target = body

func _on_MoveAreaTarget_body_exited(body):
	if body.get("TYPE") == "Player":
		state = STATE.IDLE
		target = null

func _on_AttackArea_body_entered(body):
	if body.get("TYPE") == "Player":
		state = STATE.ATTACK