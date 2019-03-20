extends Node

#variables
var state = STATE.IDLE
var newActionTimer := 10
var stunTime := 0
var target
var lastState
var attackColdown : int

#bools
var jumping = false
var attacking = false

#onready variables
onready var enemy = get_parent()

#State options
enum STATE {
	IDLE, 
	MOVE,
	STUN,
	ATTACK
	}

func _process(delta):
	enemy.VerifyDirection(target)

func stateMachine (delta):
	newActionTimer -= 1
	
	if state == STATE.IDLE:
		enemy.motion.x = 0
		enemy.anim.play("Idle")
		HandleGravity(delta)
		ResetAttacks()
		
	elif state == STATE.MOVE:
		HandleGravity(delta)
		enemy.anim.play("Run")
		HandleMoviment()
		ResetAttacks()

	elif state == STATE.ATTACK:
		enemy.anim.play("Attack")
		MakeAttack()
	
	elif state == STATE.STUN:
		ResetAttacks()
		
		if stunTime > 0:
			enemy.anim.play("Hurt")
			enemy.motion.x += 10
			stunTime -= 1
		else:
			state = lastState

func StateManager(newState):
	if state != newState && !attacking:
		state = newState

func MakeAttack():
	attacking = true
	enemy.motion.x = 0

func ResetAttacks():
	setAreaDamage(false)
	attacking = false

func HandleGravity(delta):
	if enemy.is_on_floor():
		jumping = false
		return
	
	if enemy.motion.y < 0:
		enemy.motion.y += enemy.GRAVITY * delta
	else:
		enemy.motion.y += (enemy.GRAVITY * delta ) * 2

func HandleMoviment():
	if 0 > newActionTimer && target != null:
		enemy.motion.x = enemy.SPEED * enemy.direction
	else:
		StateManager(STATE.IDLE)

func receiveDamage(stunLock : int):
	lastState = state
	stunTime = stunLock
	StateManager(STATE.STUN)

func setAreaDamage(value : bool):
	enemy.get_node("HitArea/HitShape").set_disabled(!value)

#
# Signals
#

func _on_MoveAreaTarget_body_entered(body):
	if body.get("TYPE") == "Player":
		target = body
		StateManager(STATE.MOVE)

func _on_MoveAreaTarget_body_exited(body):
	if body.get("TYPE") == "Player":
		target = null
		StateManager(STATE.IDLE)

func _on_AttackArea_body_entered(body):
	if body.get("TYPE") == "Player":
		StateManager(STATE.ATTACK)

func _on_AttackArea_body_exited(body):
	if body.get("TYPE") == "Player":
		StateManager(STATE.MOVE)

func _on_HitArea_body_entered(body):
	if body.get("TYPE") == "Player":
		body.HealthManager.doDamage(enemy.DAMAGE)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack":
		ResetAttacks()
		StateManager(STATE.MOVE)
