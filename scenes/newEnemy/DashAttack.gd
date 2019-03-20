extends Node

var stage : int = 0
var enemy
var target

func enter (enemyNode : KinematicBody2D, targetNode : KinematicBody2D) -> void:
	enemy = enemyNode
	target = targetNode
	
	if stage == 0:
		Stage0()
	elif stage == 1:
		Stage1()
	elif stage == 2:
		Stage2()

func Stage0():
	enemy.motion.x = 0
	pass

func Stage1():
	pass

func Stage2():
	pass