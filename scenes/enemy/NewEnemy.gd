extends KinematicBody2D

var motion := Vector2()
var direction := 1
var knockbackTimer := 0
var damageNumberPopup = preload("res://scenes/player/DamageNumber.tscn")

#constants
const TYPE = "Enemy"
const MOVE_SPEED := 100.0
const JUMP_SPEED := 100.0
const GRAVITY := 400.0

#onready var
onready var inputHelper = $InputManager
onready var anim = $AnimationPlayer

func _physics_process(delta):
	$StateMachine.StateMachine(delta)