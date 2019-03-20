extends Sprite

func _ready():
	$AnimationPlayer.play("Explosion")

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()