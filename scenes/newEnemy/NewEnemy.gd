extends KinematicBody2D

#variables
var motion = Vector2()
var direction = 1

#constants
const TYPE := "Enemy"
const SPEED := 50
const GRAVITY := 400

#exported variable
export (PackedScene) var enemyDeath
export (PackedScene) var damageNumber

#onready variables
onready var anim = $AnimationPlayer

func _physics_process(delta):
	$StateMachine.stateMachine(delta)
	motion = move_and_slide(motion, Vector2(0, -1))

func ShowDamage(dmg):
	var number = damageNumber.instance()
	number.setNumber(dmg)
	number.set_global_position(get_global_position())
	owner.get_parent().add_child(number)

func setDirection(newDirection : int):
	if (direction != newDirection):
		direction = newDirection
		var scale = Vector2(-1,1)
		apply_scale(scale)

func Die():
	var explosion = enemyDeath.instance()
	explosion.set_global_position(get_global_position())
	owner.get_parent().add_child(explosion)
	queue_free()

#
# signal functions
#

func _on_HealthManager_healthChanged(health, maxHealth, damage):
	ShowDamage(damage)
	
	if health == 0:
		Die()