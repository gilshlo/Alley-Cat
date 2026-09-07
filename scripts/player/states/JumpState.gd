class_name JumpState
extends CatState

func physics_update(delta: float) -> void:
	cat.apply_gravity(delta)
	cat.steer(delta, 0.55)
	cat.consume_jump()
	# Early release shortens ascent without changing gravity or the apex formula.
	if Input.is_action_just_released("jump") and cat.velocity.y < -90.0:
		cat.velocity.y *= 0.52
