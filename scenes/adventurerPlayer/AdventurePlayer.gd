extends KinematicBody2D

#Variables
var state = STATE.DEFAULT
var motion := Vector2()
var direction := 1
var jumpHeld := 0.0
var extraJumps := 0
var maxExtraJumps := 2
var colddownTimer := 0
var knockbackTimer := 0
var damageNumberPopup = preload("res://scenes/player/DamageNumber.tscn")
var attackTimer := 0

#bools
var jumping := false
var canExtraJump := false
var attackQueued = false
var readyToAttack = true

#constants
const TYPE = "Player"
const MOVE_SPEED := 100.0
const JUMP_SPEED := 100.0
const GRAVITY := 400.0
const MAX_JUMP_HELD := 10.0

#state machine options
enum STATE {
	DEFAULT, 
	SWORD_ATTACK_1, 
	SWORD_ATTACK_2, 
	SWORD_ATTACK_3, 
	KNOCKBACK
	}

#onready var
onready var inputHelper = $inputHelper
onready var anim = $AnimationPlayer

func _physics_process(delta):
	StateMachine(delta)
	reduceTimers()
	motion = move_and_slide(motion, Vector2(0,-1))

func StateMachine(delta):
	if (state == STATE.DEFAULT):
		handleDefaultAnim()
		handleInput()
		handleGravity(delta)
	elif (state == STATE.KNOCKBACK):
		doKnockBack()
	elif (state == STATE.SWORD_ATTACK_1):
		handleAttackInput()
		anim.play("SwordAttack_1")
	elif (state == STATE.SWORD_ATTACK_2):
		handleAttackInput()
		anim.play("SwordAttack_2")
	elif (state == STATE.SWORD_ATTACK_3):
		handleAttackInput()
		anim.play("SwordAttack_3")

func handleDefaultAnim():
	if motion.y == 0:
		if motion.x == 0:
			anim.play("IdleSword")
		else:
			anim.play("Run")
	elif motion.y < 0:
		anim.play("JumpUp")
	elif motion.y > 0:
		anim.play("JumpDown")

func handleInput():
	handleRunInput()
	handleJumpInput()
	handleAttackInput()

func handleRunInput():
	if (inputHelper.isMoveRightPressed()):
		motion.x = MOVE_SPEED
		setDirection(1)
		
	elif (inputHelper.isMoveLeftPressed()):
		motion.x = -MOVE_SPEED
		setDirection(-1)
	
	else:
		motion.x = 0

func handleJumpInput():
	if is_on_floor():
		if inputHelper.isJumpPressed() && !jumping:
			initialJump()
	
	elif jumping && !is_on_floor():
		heldJump()
	
	if canExtraJump:
		if inputHelper.isJumpPressed() && extraJumps > 0:
			extraJumps -= 1
			initialJump(1.2)
	
	if inputHelper.isJumpRelease():
		jumpHeld = MAX_JUMP_HELD
		canExtraJump = true
		jumping = false

func initialJump(extraJumpPower : float = 1.0):
	jumping = true
	motion.y = -JUMP_SPEED * extraJumpPower

func heldJump():
	if 0 < jumpHeld:
		canExtraJump = false
		jumpHeld -= 1 
		motion.y -= JUMP_SPEED / 10

func handleAttackInput():
	if inputHelper.isAttackJustPressed() && is_on_floor():
		motion.x = 0
		
		if state == STATE.DEFAULT:
			resetAttackBools()
			state = STATE.SWORD_ATTACK_1
			return
		
		elif state == STATE.SWORD_ATTACK_1:
			if readyToAttack:
				state = STATE.SWORD_ATTACK_2
				resetAttackBools()
				return
			else:
				attackQueued = true
				return
		
		elif state == STATE.SWORD_ATTACK_2:
			if readyToAttack:
				state = STATE.SWORD_ATTACK_3
				resetAttackBools()
				return
			else: 
				attackQueued = true
				return
	
	elif !attackQueued && readyToAttack:
		state = STATE.DEFAULT
		
	if (attackQueued and readyToAttack):
		if (state == STATE.SWORD_ATTACK_1):
			state = STATE.SWORD_ATTACK_2
			resetAttackBools()
	
		elif (state == STATE.SWORD_ATTACK_2):
			state = STATE.SWORD_ATTACK_3
			resetAttackBools()

func resetAttackBools():
	attackQueued = false
	readyToAttack = false

func doDamagePlayer(attackDamage : int = 1, attackForce : int = 10):
	showDamageNumber(attackDamage)
	knockbackTimer = attackForce
	state = STATE.KNOCKBACK

func doKnockBack():
	if knockbackTimer > 0:
		anim.play("Hurt")
		knockbackTimer -= 1
		motion.y = - 20 * knockbackTimer
		motion.x = (30) * (direction * -1) * knockbackTimer
	else:
		knockbackTimer = 0
		state = STATE.DEFAULT

func showDamageNumber(dmgNumber : int):
	var dmgPopUp = damageNumberPopup.instance()
	dmgPopUp.setNumber(dmgNumber)
	dmgPopUp.set_position(get_node("CenterPos").get_global_position())
	get_parent().add_child(dmgPopUp)

func handleGravity(delta):
	if is_on_floor():
		resetJump()
		return
	
	if motion.y < 0:
		motion.y += GRAVITY * delta
	else:
		motion.y += (GRAVITY * delta ) * 2

func resetJump():
	extraJumps = maxExtraJumps
	canExtraJump = false

func reduceTimers():
	if 0 < colddownTimer:
		colddownTimer -= 1

func setDirection(newDirection : int):
	if (direction != newDirection):
		direction = newDirection
		var scale = Vector2(-1,1)
		apply_scale(scale)
		
		"""
		set_global_transform(Transform2D(Vector2(direction,0),Vector2(0,1),Vector2(position.x,position.y)))
		"""

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "SwordAttack_1" || anim_name == "SwordAttack_2" || anim_name == "SwordAttack_3":
		readyToAttack = true