extends KinematicBody2D

# regular vars
var state = STATE.DEFAULT
var velocity = Vector2(0, 0)
var direction = -1
var health = 5
var maxHealth = 5
var spirit = 10
var tongue
var highestDistanceMovedInTongue = 0
var inVineCount = 0
var vineXPos = 0
var tempMaxVelocityX = 0
var snapVector = SNAP_VECTOR
var slideDir = 1
var airFriction = 0

# bools
var ignoreGravity = false
var grounded = false
var jumping = false
var jumpHeld = false
var verticalBarrelShot = false
var knockbackFlip = false
var blinkDuringImmune = true
var ableToQueueAttack = false
var attackQueued = false
var readyToAttack = false
var onWall = false
var postWallJump = false
var postWallJumpOff = false

# timers
var justLeftVineTimer = 0
var inAirTimer = 0.0
var barrelAirTimer = 0.0
var dashTimer = 0.0
var healHeldTimer = 0.0
var immuneTimer = 0.0
var knockbackTimer = 0
var visibleTimer = 0
var meleeAttackTime = 0
var hangTimer = 0
var dashCooldownTimer = 0
var wallSlideStickTimer = 0

# constants
const SNAP_VECTOR = Vector2(0, 4)
const MOVE_SPEED = 75
const GRAVITY = 600
const JUMP_SPEED = 80
const MAX_AIR_TIME = 18
const FLOOR_ANGLE_TOLERANCE = 40
const MAX_BARREL_AIR_TIME = 18
const DASH_TIME = 5
const DASH_IMMUNE_TIME = 5
const DASH_SPEED = 640
const HEAL_HOLD_TIME = 30
const IMMUNE_TIME = 60
const KNOCKBACK_TIME = 10
const ATTACK_ONE_DAMAGE = 1
const ATTACK_TWO_DAMAGE = 1
const ATTACK_THREE_DAMAGE = 2
const MAX_HANG_TIME = 300
const JUST_LEFT_VINE_TIME = 10
const DASH_COOLDOWN_TIME = 30
const WALL_SLIDE_STICK_TIME = 5
const WALL_JUMP_AIR_FRICTION = 5

# onready vars
onready var sprite = get_node("Sprite")
onready var game = get_tree().get_root().get_node("base/game")
onready var anim = get_node("Sprite/AnimationPlayer")
onready var inputHelper = get_tree().get_root().get_node("base/constants/input-helper")
onready var tween = get_node("Tween")

enum STATE {
	DEFAULT,
	BARRELLAUNCH,
	BARREL,
	KNOCKBACK,
	TONGUE_GRAPPLE,
	TONGUE_LAUNCH,
	MELEE_ONE,
	MELEE_TWO,
	MELEE_THREE,
	CLIMB,
	DASH,
	WALL_SLIDE
}

const COLL_LAYER = {
	"WALL": 1,
	"ENEMY": 19,
}

func _ready():
	get_node("hitboxArea2D").add_to_group("player")
	add_to_group("player")
	get_node("hitboxArea2D").connect("area_entered", self, "hitboxAreaEnter")
	get_node("attackArea2D1").connect("body_entered", self, "attackAreaEnter")
	get_node("attackArea2D2").connect("body_entered", self, "attackAreaEnter")
	get_node("attackArea2D3").connect("body_entered", self, "attackAreaEnter")
	pass

func attackAreaEnter(body):
	if (body.is_in_group("enemy")):
		if (state == STATE.MELEE_ONE):
			body.doHurt(ATTACK_ONE_DAMAGE)
		elif (state == STATE.MELEE_TWO):
			body.doHurt(ATTACK_TWO_DAMAGE)
		elif (state == STATE.MELEE_THREE):
			body.doHurt(ATTACK_THREE_DAMAGE)

func enableAttackAreaColl():
	if (state == STATE.MELEE_ONE):
		get_node("attackArea2D1").set_collision_layer_bit(COLL_LAYER.ENEMY, true)
	elif (state == STATE.MELEE_TWO):
		get_node("attackArea2D2").set_collision_layer_bit(COLL_LAYER.ENEMY, true)
	elif (state == STATE.MELEE_THREE):
		get_node("attackArea2D3").set_collision_layer_bit(COLL_LAYER.ENEMY, true)

func disableAttackAreaColl():
	get_node("attackArea2D1").set_collision_layer_bit(COLL_LAYER.ENEMY, false)
	get_node("attackArea2D2").set_collision_layer_bit(COLL_LAYER.ENEMY, false)
	get_node("attackArea2D3").set_collision_layer_bit(COLL_LAYER.ENEMY, false)

func hitboxAreaEnter(area):
	var damage = 1
	if (area.get_parent().get("damage")):
		damage = area.get_parent().damage
	
	doHurt(damage, area.global_position)

func doHurt(damage, pos):
	if (immuneTimer != 0):
		return
	
	setModulateRed()
	blinkDuringImmune = true
	
	if (global_position.x > pos.x):
		knockbackFlip = false
	else: 
		knockbackFlip = true
	
	immuneTimer = IMMUNE_TIME
	var tempHealth = health - damage
	if (tempHealth < 0):
		health = 0
	else:
		health = tempHealth
	
	knockbackTimer = KNOCKBACK_TIME
	state = STATE.KNOCKBACK

func stateMachine(delta):
	handleImmuneTimers(delta)
	handleCooldownTimers()
	
	if (state != STATE.DASH):
		set_collision_mask_bit(COLL_LAYER.ENEMY, true)
		set_collision_layer_bit(COLL_LAYER.ENEMY, true)
	
	if (state != STATE.BARREL and state != STATE.BARRELLAUNCH and state != STATE.WALL_SLIDE):
		handleGravity(delta)
	
	if (state == STATE.DEFAULT):
		handleDefaultAnim()
		handleInput(delta)
		handleTimers(delta)
		handleHealInput(delta)
	elif (state == STATE.BARREL):
		return
	elif(state == STATE.BARRELLAUNCH):
		handleBarrelTimers(delta)
		handleBarrelInput()
		anim.startAnim("roll")
	elif (state == STATE.DASH):
		anim.startAnim("dash")
		dash()
		handleDashTimer()
	elif (state == STATE.KNOCKBACK):
		doKnockback()
	elif (state == STATE.TONGUE_GRAPPLE):
		handleTongueTimers()
		doTongueGrapple(delta)
	elif (state == STATE.MELEE_ONE):
		anim.startAnim("melee-1")
		handleMeleeInput()
	elif (state == STATE.MELEE_TWO):
		anim.startAnim("melee-2")
		meleeAttackTime = meleeAttackTime + 1
		handleMeleeInput()
	elif (state == STATE.MELEE_THREE):
		anim.startAnim("melee-3")
		meleeAttackTime = meleeAttackTime + 1
		var movement = 20 - meleeAttackTime
		if (movement < 1):
			movement = 1
		velocity.x = velocity.x + movement * direction * 0.03
	elif (state == STATE.CLIMB):
		handleClimbInput()
	elif (state == STATE.TONGUE_LAUNCH):
		return
	elif (state == STATE.WALL_SLIDE):
		handleWallSlide()

#
# START INPUT
#

func handleClimbInput():
	velocity.x = 0
	velocity.y = 0
	if (inputHelper.isJumpJustPressed()):
		justLeftVineTimer = JUST_LEFT_VINE_TIME
		setStateDefault()
		initialJump()
		return
	
	if (inputHelper.isMoveLeftJustPressed()):
		setDirection(1)
		global_position.x = vineXPos - 4 * direction
	elif (inputHelper.isMoveRightJustPressed()):
		setDirection(-1)
		global_position.x = vineXPos - 4 * direction
	
	if (inputHelper.isMoveUpPressed()):
		velocity.y = -40
	elif (inputHelper.isMoveDownPressed()):
		velocity.y = 40
	else:
		velocity.y = 0
	
	if (velocity.y != 0):
		anim.startAnim("climb")
	else:
		anim.stop()
		sprite.frame = 0

func handleBarrelInput():
	if (verticalBarrelShot):
		if (inputHelper.isMoveRightPressed()):
			velocity.x = 40
		elif (inputHelper.isMoveLeftPressed()):
			velocity.x = -40
		else:
			velocity.x = 0

func handleInput(delta):
	handleRunInput(delta)
	handleJumpInput(delta)
	handleDashInput()
	handleTongueInput()
	handleMeleeInput()
	handleStartClimbInput()
	handleShootInput()

func handleStartClimbInput():
	if (justLeftVineTimer > 0):
		justLeftVineTimer = justLeftVineTimer - 1
		return
	if (inVineCount > 0):
		if (inputHelper.isMoveUpPressed()):
			global_position.x = vineXPos - 4 * direction
			state = STATE.CLIMB

func handleDashInput():
	if (inputHelper.isDashJustPressed() and dashCooldownTimer == 0):
		set_collision_mask_bit(COLL_LAYER.ENEMY, false)
		set_collision_layer_bit(COLL_LAYER.ENEMY, false)
		state = STATE.DASH
		anim.startAnim("dash")
		dashTimer = DASH_TIME
		immuneTimer = DASH_IMMUNE_TIME

func handleJumpInput(delta):
	if (grounded && inputHelper.isJumpJustPressed()):
		initialJump()
	elif (!grounded && jumpHeld && jumping && inAirTimer < MAX_AIR_TIME && inputHelper.isJumpHeld()):
		heldJump(delta)
	elif (!inputHelper.isJumpHeld()):
		jumpHeld = false


func handleRunInput(delta):
	if (inputHelper.isMoveRightPressed()):
		if (grounded):
			snapVector = SNAP_VECTOR
		
		if (postWallJump):
			if (slideDir == -1):
				postWallJumpOff = true
				postWallJump = false
			handleWallJumpFriction(WALL_JUMP_AIR_FRICTION, 1)
		elif (postWallJumpOff):
			velocity.x = MOVE_SPEED * 1.5
		else:
			velocity.x = MOVE_SPEED
			if (tempMaxVelocityX > MOVE_SPEED):
				velocity.x = tempMaxVelocityX
		
		setDirection(1)
	elif (inputHelper.isMoveLeftPressed()):
		if (grounded):
			snapVector = SNAP_VECTOR
		
		if (postWallJump):
			if (slideDir == 1):
				postWallJumpOff = true
				postWallJump = false
			handleWallJumpFriction(WALL_JUMP_AIR_FRICTION, -1)
		elif (postWallJumpOff):
			velocity.x = -MOVE_SPEED * 1.5
		else:
			velocity.x = -MOVE_SPEED
			if (tempMaxVelocityX > MOVE_SPEED):
				velocity.x = -tempMaxVelocityX
		
		setDirection(-1)
	else:
		if (!grounded):
			handleFriction(1000)
		else:
			handleFriction(10)

func handleWallJumpFriction(friction, dir):
	velocity.x = velocity.x + friction * dir
	
	if (velocity.x < -MOVE_SPEED):
		velocity.x = -MOVE_SPEED
	elif (velocity.x > MOVE_SPEED):
		velocity.x = MOVE_SPEED

func handleFriction(friction):
	if (velocity.x > friction):
		velocity.x = velocity.x - friction
	elif (velocity.x < -friction):
		velocity.x = velocity.x + friction
	else:
		velocity.x = 0
		snapVector = Vector2(0, 0)

func handleDefaultAnim():
	if (state == STATE.WALL_SLIDE):
		return
	
	if (velocity.y == 0):
		if (velocity.x == 0):
			anim.startAnim("idle")
		else:
			anim.startAnim("run")
	elif (velocity.y < 0):
		anim.startAnim("jump-up")
	elif (velocity.y > 0):
		anim.startAnim("jump-down")

func handleHealInput(delta):
	if (health == maxHealth):
		return
	if (inputHelper.isUseHeld()):
		if (healHeldTimer > HEAL_HOLD_TIME):
			healHeldTimer = 0
			heal()
		else:
			healHeldTimer = healHeldTimer + 1
	else:
		healHeldTimer = 0

func handleTongueInput():
	if (inputHelper.isTongueJustPressed() and !tongue):
		hangTimer = 0
		#var scene = preload("res://scenes/player/tongue.tscn")
		#var node = scene.instance()
		#var pos = global_position
		#pos.y = pos.y - 2
		#pos.x = pos.x - 6
		#node.global_position = pos
		#node.player = self
		#node.direction = direction
		#get_tree().get_root().get_node("base/game/temp").add_child(node)
		#tongue = node
		#tongue.scale.x = tongue.scale.x * direction
		#tongue.activate()

func handleMeleeInput():
	if (inputHelper.isMeleeAttackJustPressed() and grounded):
		velocity = Vector2(0, 0)
		if (state == STATE.DEFAULT):
			resetAttackBools()
			state = STATE.MELEE_ONE
		elif (state == STATE.MELEE_ONE and ableToQueueAttack):
			if (!readyToAttack):
				attackQueued = true
				return
			resetAttackBools()
			state = STATE.MELEE_TWO
		elif (state == STATE.MELEE_TWO and ableToQueueAttack):
			if (!readyToAttack):
				attackQueued = true
				return
			resetAttackBools()
			state = STATE.MELEE_THREE
	if (attackQueued and readyToAttack):
		if (state == STATE.MELEE_ONE):
			resetAttackBools()
			state = STATE.MELEE_TWO
		elif (state == STATE.MELEE_TWO):
			resetAttackBools()
			state = STATE.MELEE_THREE

func handleShootInput():
	if (inputHelper.isShootJustPressed()):
		spawnBullet()

#
# END INPUT
#

func spawnBullet():
	var mousePos = get_global_mouse_position()
	var scene = load("res://scenes/player/bullet.tscn")
	var node = scene.instance()
	node.position = position
	node.destination = mousePos
	get_tree().get_root().get_node("base/game/temp").add_child(node)

func handleTongueTimers():
	if (hangTimer < MAX_HANG_TIME):
		hangTimer = hangTimer + 1
		anim.startAnim("hang")
	else:
		anim.startAnim("hang-panic")

func setModulateRed():
	modulate = Color(255,0,0,10)

func setModulateNormal():
	modulate = Color(1,1,1,1)

func setStateDefault():
	state = STATE.DEFAULT

func setStateLaunch():
	state = STATE.TONGUE_LAUNCH

func setAbleToQueueAttack():
	readyToAttack = false
	ableToQueueAttack = true

func setReadyToAttack():
	readyToAttack = true

func endMelee():
	setStateDefault()
	resetAttackBools()
	disableAttackAreaColl()

func resetAttackBools():
	attackQueued = false
	readyToAttack = false
	ableToQueueAttack = false
	meleeAttackTime = 0

func doTongueGrapple(delta):
	var tonguePos = tongue.get_node("innards/rotate_point").global_position
	var changeX = abs(global_position.x - tonguePos.x)
	var changeY = abs(global_position.y - tonguePos.y)
	if (changeY > highestDistanceMovedInTongue):
		highestDistanceMovedInTongue = changeY
	if (changeX > highestDistanceMovedInTongue):
		highestDistanceMovedInTongue = changeX
	
	tonguePos.x = tonguePos.x - 2
	tonguePos.y = tonguePos.y - 2
	global_position = tonguePos
#	global_position = tongue.global_position
#	velocity.y = velocity.y - 1 * changeY * 5
	
#	global_position.y = pos.y - y
#	global_position.x = pos.x + x
	
#	tongue.global_position.x = tongue.global_position.x - x
#	tongue.global_position.y = tongue.global_position.y - y

func setTongueGrapple():
	state = STATE.TONGUE_GRAPPLE


func doKnockback():
	if (knockbackTimer > 0):
		knockbackTimer = knockbackTimer - 1
		velocity = Vector2(100, -50)
		velocity.y = velocity.y - (knockbackTimer - KNOCKBACK_TIME) * 4
		if (knockbackFlip):
			velocity.x = -velocity.x
	else:
		state = STATE.DEFAULT

func handleImmuneTimers(delta):
	if (immuneTimer > 0):
		immuneTimer = immuneTimer - 1
	else:
		immuneTimer = 0
		visibleTimer = 0
	
	if (IMMUNE_TIME - immuneTimer > 4):
		setModulateNormal()
	
	if (immuneTimer < 10):
		sprite.show()
		visibleTimer = 0
		return
	
	if (sprite.visible and visibleTimer > 8 and blinkDuringImmune):
		sprite.hide()
		visibleTimer = 0
	elif (!sprite.visible and visibleTimer > 4 and blinkDuringImmune):
		sprite.show()
		visibleTimer = 0
	visibleTimer = visibleTimer + 1

func heal():
	health = health + 1
	print("HEAL")

func dash():
	jumping = false
	velocity.y = 0
	velocity.x = DASH_SPEED * direction
	blinkDuringImmune = false

func doBounce(bounceVelocity):
	if (state == STATE.BARRELLAUNCH):
		setStateDefault()
	velocity.y = bounceVelocity
	setGrounded(false)

func setGrounded(isGrounded):
	if (isGrounded):
		airFriction = 1000
		snapVector = SNAP_VECTOR
		position.y = floor(position.y) + 1
		grounded = true
		ignoreGravity = false
		tempMaxVelocityX = 0
		checkIfLandAfterLaunch()
	else:
		grounded = false
		snapVector = Vector2(0, 0)

func checkIfLandAfterLaunch():
	if (state == STATE.BARRELLAUNCH || state == STATE.TONGUE_LAUNCH):
		setStateDefault()
		barrelAirTimer = 0

func handleBarrelTimers(delta):
	if (barrelAirTimer < MAX_BARREL_AIR_TIME):
		barrelAirTimer = barrelAirTimer + 1
	elif (!ignoreGravity):
		velocity.y = velocity.y + 5

func shootOutOfBarrel(newVelocity, newPosition, ignoreGravityAfterShot):
	ignoreGravity = ignoreGravityAfterShot
	global_position = newPosition
	if (newVelocity.y != 0):
		verticalBarrelShot = true
	else:
		verticalBarrelShot = false
	velocity = newVelocity
	show()
	state = STATE.BARRELLAUNCH

func setInBarrel():
	hide()
	barrelAirTimer = 0
	state = STATE.BARREL
	velocity = Vector2(0, 0)

func resetJump():
	postWallJumpOff = false
	postWallJump = false
	jumping = false
	jumpHeld = false

func handleTimers(delta):
	if (jumping):
		inAirTimer = inAirTimer + 1
	else:
		inAirTimer = 0

func handleCooldownTimers():
	if (dashCooldownTimer > 0):
		dashCooldownTimer = dashCooldownTimer - 1

func handleDashTimer():
	if (dashTimer > 0):
		dashTimer = dashTimer - 1
	else:
		velocity.x = 0
		dashCooldownTimer = DASH_COOLDOWN_TIME
		setStateDefault()

func heldJump(delta):
	if (postWallJumpOff):
		velocity.y += (-JUMP_SPEED + inAirTimer) / 2
		
		if (velocity.y < -JUMP_SPEED):
			velocity.y = -(JUMP_SPEED) + inAirTimer
		
	else:
		velocity.y += (-JUMP_SPEED + inAirTimer)
		
		if (velocity.y < -JUMP_SPEED * 1.5):
			velocity.y = -(JUMP_SPEED * 1.5) + inAirTimer

func initialJump():
	setGrounded(false)
	jumping = true
	jumpHeld = true
	velocity.y = -JUMP_SPEED

func wallJump(isOnWallStill=false):
	inAirTimer = 0
	setGrounded(false)
	setStateDefault()
	jumping = true
	jumpHeld = true
	if (isOnWallStill):
		postWallJump = true
		velocity.y = -JUMP_SPEED
		velocity.x = MOVE_SPEED * -direction
	else:
		postWallJumpOff = true
		velocity.y = -JUMP_SPEED
		velocity.x = MOVE_SPEED * -direction * 3

func handleWallSlide():
	anim.startAnim("wall-slide")
	handleWallSlideGravity()
	
	if (grounded):
		wallSlideStickTimer = 0
		setStateDefault()
		return
	
	if (inputHelper.isMoveLeftPressed() and slideDir == -1):
		velocity.x = slideDir
		if (inputHelper.isJumpJustPressed()):
			wallJump(true)
			return
	elif (inputHelper.isMoveRightPressed() and slideDir == 1):
		velocity.x = slideDir
		if (inputHelper.isJumpJustPressed()):
			wallJump(true)
			return
	
	if (onWall):
		wallSlideStickTimer = 0
		if (inputHelper.isJumpJustPressed()):
			wallJump()
	else:
		wallSlideStickTimer = wallSlideStickTimer + 1
		if (inputHelper.isJumpJustPressed()):
			wallJump()
	
	if (wallSlideStickTimer > WALL_SLIDE_STICK_TIME):
		wallSlideStickTimer = 0
		setStateDefault()

func handleWallSlideGravity():
	velocity.y = 25

func handleGravity(delta):
	if (grounded):
		velocity.y = 0
		resetJump()
		return
	
	if (ignoreGravity):
		return
	
	velocity.y += GRAVITY * delta
	if (velocity.y > 400):
		velocity.y = 400

func setDirection(newDirection):
	if (direction != newDirection):
		direction = newDirection
		set_global_transform(Transform2D(Vector2(-direction,0),Vector2(0,1),Vector2(position.x,position.y)))

func _physics_process(delta):
	if (game.pauseUnits):
		return
	
	stateMachine(delta)
	if (state != STATE.TONGUE_GRAPPLE):
		move_and_slide_with_snap(velocity, snapVector, Vector2(0, -1), true)
		
		if (velocity.y > 0 and is_on_wall()):
			postWallJump = false
			postWallJumpOff = false
			if (velocity.x > 0):
				slideDir = 1
			else:
				slideDir = -1
			
			velocity.x = 0
			onWall = true
			if (state == STATE.DEFAULT and !grounded):
				state = STATE.WALL_SLIDE
		else:
			onWall = false
		
		if (is_on_ceiling()):
			velocity.y = 0
			jumping = false
	
	if (health == 0):
		health = maxHealth
	
	drawPath()

func drawPath():
	var scene = load("res://scenes/dev/point.tscn")
	var node = scene.instance()
	node.position = position
	get_parent().add_child(node)