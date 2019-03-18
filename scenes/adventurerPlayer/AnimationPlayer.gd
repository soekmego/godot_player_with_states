extends AnimationPlayer

var animation = null

func animationFinished():
	if animation == null:
		return null
	else :
		return animation 

func _on_AnimationPlayer_animation_finished(anim_name):
	animation = anim_name

func _on_AnimationPlayer_animation_changed(old_name, new_name):
	animation = null
