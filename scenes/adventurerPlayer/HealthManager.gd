extends Node

signal healthChanged(health, maxHealth, damage)

export (int) var maxHealth : int = 5
export (int) var health : int

func _ready():
	health = maxHealth

func doDamage (damage : int):
	health -= damage
	health = int(max(0, health))
	emit_signal("healthChanged", health, maxHealth, damage)

func healDamage (damage : int):
	health += damage
	health = int(min(health, maxHealth))
	emit_signal("healthChanged", health, maxHealth, damage)