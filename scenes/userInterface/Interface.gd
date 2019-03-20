extends Control

signal InterfaceLifeChange(hp, maxhp)

func _on_HealthManager_healthChanged(health, maxHealth, damage, heal):
	emit_signal("InterfaceLifeChange", health, maxHealth)