extends HBoxContainer

export (PackedScene) var HealthFull
export (PackedScene) var HealthEmpty


func setLifeBar(actualHP : int, maxHP : int):
	var lifeFull = actualHP
	var lifeEmpty = maxHP - actualHP
	
	for child in get_children():
		child.queue_free()
	
	for i in lifeFull:
		add_child(HealthFull.instance())
		
	for i in lifeEmpty:
		add_child(HealthEmpty.instance())

func _on_Interface_InterfaceLifeChange(hp, maxhp):
	setLifeBar(hp, maxhp)
