extends KinematicBody2D



func _on_Shoking_Area_body_entered(body):
	if body.get("TYPE") == "Player":
		body.doDamagePlayer(3, 10)

	pass # Replace with function body.
