extends KinematicBody2D

#Variables
var state = STATE.DEFAULT
var motion := Vector2()
var direction := 1
var jumpHeld := 0
var extraJumps := 0
var maxExtraJumps := 1
var colddownTimer := 0

#bools
var jumping := false

#constants
const MOVE_SPEED = 100
const JUMP_SPEED = 100
const GRAVITY = 400
const MAX_JUMP_HELD = 10

#state machine options
enum STATE {DEFAULT, CROUCH, KNOCKBACK}

#onready var
onready var inputHelper = $inputHelper
onready var anim = $AnimationPlayer

func _ready():
	pass

func _physics_process(delta):
	StateMachine(delta)
	reduceTimers()
	motion = move_and_slide(motion, Vector2(0,-1))


func StateMachine(delta):
	if (state == STATE.DEFAULT):
		handleDefaultAnim()
		handleInput(delta)
		handleGravity(delta)
	if (state == STATE.KNOCKBACK):
		doKnockBack()
	if (state == STATE.CROUCH):
		handleCrouchInput(delta)
		handleCrouch(delta)
		handleGravity(delta)

func handleDefaultAnim():
	if motion.y == 0:
		if motion.x == 0:
			anim.play("Idle")
		else:
			anim.play("Run")
	elif motion.y < 0:
		anim.play("JumpUp")
	elif motion.y > 0:
		anim.play("JumpDown")

func handleInput(delta):
	handleCrouchInput(delta)
	handleRunInput(delta)
	handleJumpInput(delta)

func handleRunInput(delta):
	if (inputHelper.isMoveRightPressed()):
		motion.x = MOVE_SPEED
		setDirection(1)
		
	elif (inputHelper.isMoveLeftPressed()):
		motion.x = -MOVE_SPEED
		setDirection(-1)
	
	else:
		motion.x = 0

func handleJumpInput(delta):
	if is_on_floor():
		if inputHelper.isJumpPressed() && !jumping:
			initialJump()
	
	elif jumping && !is_on_floor():
		heldJump(delta)

	if inputHelper.isJumpRelease():
		jumpHeld = MAX_JUMP_HELD
		jumping = false


func initialJump(extraJumpPower : int = 1):
	jumping = true
	motion.y = -JUMP_SPEED * extraJumpPower

func heldJump(delta):
	if 0 < jumpHeld:
		jumpHeld -= 1 
		motion.y -= JUMP_SPEED / 10

func handleCrouchInput(delta):
	if colddownTimer > 0: return
	
	if inputHelper.isMoveDownPressed():
		state = STATE.CROUCH

	if inputHelper.isMoveDownRelease():
		state = STATE.DEFAULT
		
	if inputHelper.isMoveDownPressed() && inputHelper.isJumpPressed() && is_on_floor():
		colddownTimer = 30
		initialJump(2)
		state = STATE.DEFAULT

func handleCrouch(delta):
	if is_on_floor():
		anim.play("Crouch")
	
	motion.x = 0
	if !is_on_floor() && motion.y < 0:
		motion.y = 0
		anim.play("JumpDown")

func receiveDamage():
	pass #receive damage in this function then change the state to KNOCKBACK

func doKnockBack():
	pass #cause the effect of the knockback and change the state to DEFAULT

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