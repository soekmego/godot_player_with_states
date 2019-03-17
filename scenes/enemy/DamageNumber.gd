extends Position2D

func _ready():
	$AnimationPlayer.play("Damage")

func setNumber(number : int) -> void:
	$Label.text = str(number)

func _on_AnimationPlayer_animation_finished(anim_name) -> void:
	if anim_name == "Damage":
		queue_free()

func setDirection(direction : int):
	if direction == -1:
		var scale = Vector2(-1,1)
		apply_scale(scale)